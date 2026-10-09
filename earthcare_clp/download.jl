#=
Download ACM_CLP granules from the EarthCARE MAAP catalogue.

A granule is one product file: one orbit frame of about 5000 km of ground
track. Directories, dates, and baseline are in earthcare_settings.jl.
The token is read from EARTHCARE_MAAP_TOKEN.

The catalogue is a STAC API. Search is a GET on /catalogue/search with
`collections`, `datetime`, `productType`, `limit`, and `startRecord` for
paging. Each item carries the .h5 file under assets["enclosure_h5"].
The offline token is exchanged for a short-lived access token at the MAAP
identity server, as in earthcarekit and the ESA data access example at
https://catalog.maap.eo.esa.int/doc/examples/ESAMAAP_ecdataaccess.html .
=#
import Dates
import Downloads
import JSON3


include("earthcare_settings.jl")

# Offline token from https://portal.maap.eo.esa.int/ini/services/auth/token/
haskey(ENV, "EARTHCARE_MAAP_TOKEN") ||
    error("Set EARTHCARE_MAAP_TOKEN to an offline token from https://portal.maap.eo.esa.int/ini/services/auth/token/")
const OFFLINE_TOKEN = ENV["EARTHCARE_MAAP_TOKEN"]

# MAAP catalogue and identity server. Fixed.
const SEARCH_URL = "https://catalog.maap.eo.esa.int/catalogue/search"
const IAM_URL = "https://iam.maap.eo.esa.int/realms/esa-maap/protocol/openid-connect/token"
# Public client credentials from the ESA MAAP data access example,
# https://catalog.maap.eo.esa.int/doc/examples/ESAMAAP_ecdataaccess.html
const IAM_CLIENT_ID = "offline-token"
const IAM_CLIENT_SECRET = "p1eL7uonXs6MDxtGbgKdPVRAmnGxHpVE"
const COLLECTION = "JAXAL2Validated_MAAP"
const PRODUCT_TYPE = "ACM_CLP"
const PAGE_SIZE = 200

"""
    access_token(offline_token)

Exchange a MAAP offline token for an access token.
"""
function access_token(offline_token)
    form = join(
        [
            "client_id=$(escape_form(IAM_CLIENT_ID))",
            "client_secret=$(escape_form(IAM_CLIENT_SECRET))",
            "grant_type=refresh_token",
            "refresh_token=$(escape_form(offline_token))",
            "scope=$(escape_form("offline_access openid"))",
        ],
        "&",
    )
    io = IOBuffer()
    response = Downloads.request(
        IAM_URL;
        method = "POST",
        input = IOBuffer(form),
        headers = ["Content-Type" => "application/x-www-form-urlencoded"],
        output = io,
    )
    body = JSON3.read(String(take!(io)))
    if response.status != 200 || !haskey(body, :access_token)
        msg = get(body, :error_description, get(body, :error, "no error message"))
        error("MAAP token exchange failed with HTTP $(response.status): $msg. " *
              "Get a new offline token at https://portal.maap.eo.esa.int/ini/services/auth/token/")
    end
    return String(body.access_token)
end

# Percent-encode a form field value.
function escape_form(s::AbstractString)
    safe = Set(vcat('a':'z', 'A':'Z', '0':'9', ['-', '_', '.', '~']))
    return join(c in safe ? string(c) : join("%" * uppercase(string(b, base = 16, pad = 2)) for b in codeunits(string(c))) for c in s)
end

stac_time(t::Dates.DateTime) = Dates.format(t, "yyyy-mm-ddTHH:MM:SSZ")

"""
    retry(f, what; attempts = 5)

Call `f()` and retry on a `Downloads.RequestError` with backoff.
"""
function retry(f, what; attempts = 5)
    for attempt in 1:attempts
        try
            return f()
        catch err
            err isa Downloads.RequestError || rethrow()
            attempt == attempts && rethrow()
            wait_s = 5 * 2^(attempt - 1)
            @warn "$what failed (attempt $attempt of $attempts), retrying in $wait_s s" err.message
            sleep(wait_s)
        end
    end
end

"""
    fetch_json(url)

GET `url` and parse the body as JSON.
"""
function fetch_json(url)
    io = IOBuffer()
    Downloads.download(url, io)
    return JSON3.read(String(take!(io)))
end

"""
    granule_urls(t0, t1)

.h5 download URLs for every ACM_CLP granule starting in [`t0`, `t1`).
Searched one page at a time with `startRecord` paging.
"""
function granule_urls(t0::Dates.DateTime, t1::Dates.DateTime)
    urls = String[]
    start_record = 1
    while true
        query = join(
            [
                "collections=$COLLECTION",
                "datetime=$(stac_time(t0))/$(stac_time(t1))",
                "productType=$PRODUCT_TYPE",
                "limit=$PAGE_SIZE",
                "startRecord=$start_record",
            ],
            "&",
        )
        page = retry(() -> fetch_json("$SEARCH_URL?$query"), "search $(stac_time(t0)) page at $start_record")
        for item in page.features
            push!(urls, String(item.assets.enclosure_h5.href))
        end
        start_record += length(page.features)
        (isempty(page.features) || start_record > page.numberMatched) && break
    end
    return urls
end

# Month boundaries covering [t0, t1), so each search is small and a retry is cheap.
function month_windows(t0::Dates.DateTime, t1::Dates.DateTime)
    starts = Dates.DateTime[t0]
    next = Dates.firstdayofmonth(t0) + Dates.Month(1)
    while next < t1
        push!(starts, next)
        next += Dates.Month(1)
    end
    return [(s, i == length(starts) ? t1 : starts[i + 1]) for (i, s) in enumerate(starts)]
end

mkpath(GRANULE_DIR)
# Filenames look like ECA_JXBB_ACM_CLP_2B_<start>Z_<processing>Z_<orbit><frame>.h5
baseline(url) = split(basename(url), "_")[2]

urls = String[]
for (t0, t1) in month_windows(START_DATE, END_DATE)
    month_urls = granule_urls(t0, t1)
    @info "$(Dates.format(t0, "yyyy-mm-dd")) to $(Dates.format(t1, "yyyy-mm-dd")): $(length(month_urls)) granules"
    append!(urls, month_urls)
end
@info "Found $(length(urls)) granules"
if !isempty(BASELINE)
    filter!(url -> baseline(url) == BASELINE, urls)
    @info "Kept $(length(urls)) granules with baseline $BASELINE"
end

# Concurrent downloads. Downloads.jl runs them on one thread through libcurl.
const N_PARALLEL = 8

# Access tokens are short-lived, so one is fetched per batch of downloads.
const TOKEN_LIFETIME = Dates.Minute(20)
const token_lock = ReentrantLock()
token_fetched = Dates.DateTime(0)
headers = Pair{String, String}[]
function auth_headers()
    lock(token_lock) do
        global token_fetched, headers
        if Dates.now() - token_fetched > TOKEN_LIFETIME
            headers = ["Authorization" => "Bearer $(access_token(OFFLINE_TOKEN))"]
            token_fetched = Dates.now()
        end
        return headers
    end
end

function download_granule(url)
    dest = joinpath(GRANULE_DIR, basename(url))
    isfile(dest) && return :skipped
    retry(basename(dest)) do
        Downloads.download(url, dest * ".part"; headers = auth_headers())
        mv(dest * ".part", dest; force = true)
    end
    return :downloaded
end

todo = filter(url -> !isfile(joinpath(GRANULE_DIR, basename(url))), urls)
@info "$(length(urls) - length(todo)) already present, $(length(todo)) to download with $N_PARALLEL workers"

queue = Channel{String}(length(todo))
foreach(url -> put!(queue, url), todo)
close(queue)
done = Threads.Atomic{Int}(0)
@sync for _ in 1:N_PARALLEL
    @async for url in queue
        download_granule(url)
        n = Threads.atomic_add!(done, 1) + 1
        n % 10 == 0 && @info "$n / $(length(todo)) downloaded"
    end
end
@info "Finished: $(done[]) downloaded"

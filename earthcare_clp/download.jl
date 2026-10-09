#=
Download ACM_CLP granules from the EarthCARE MAAP catalogue.

A granule is one product file: one orbit frame of about 5000 km of ground
track. Settings are the environment variables listed below.

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
using ClimaArtifactsHelper: download_rate_callback

# Settings, all environment variables.
#
# | Variable              | Default                 | Meaning                                   |
# |-----------------------|-------------------------|-------------------------------------------|
# | EARTHCARE_MAAP_TOKEN  | required                | offline token from the MAAP portal        |
# | EARTHCARE_CLP_DIR     | <this folder>/granules  | where the .h5 granules are written        |
# | EARTHCARE_START       | 2024-06-01T00:00:00     | first granule start time, ISO format      |
# | EARTHCARE_END         | now                     | last granule start time, ISO format       |
#
# Token page: https://portal.maap.eo.esa.int/ini/services/auth/token/
# A two-hour window is one orbit, about 8 granules, for a test run.
haskey(ENV, "EARTHCARE_MAAP_TOKEN") ||
    error("Set EARTHCARE_MAAP_TOKEN to an offline token from https://portal.maap.eo.esa.int/ini/services/auth/token/")
const OFFLINE_TOKEN = ENV["EARTHCARE_MAAP_TOKEN"]
const GRANULE_DIR = get(ENV, "EARTHCARE_CLP_DIR", joinpath(@__DIR__, "granules"))
# Defaults cover the whole mission. The catalogue holds ACM_CLP from mid 2024
# onward, about 3400 granules per month.
const START_DATE = Dates.DateTime(get(ENV, "EARTHCARE_START", "2024-06-01T00:00:00"))
const END_DATE = haskey(ENV, "EARTHCARE_END") ? Dates.DateTime(ENV["EARTHCARE_END"]) : Dates.now(Dates.UTC)

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
            "client_id=$IAM_CLIENT_ID",
            "client_secret=$IAM_CLIENT_SECRET",
            "grant_type=refresh_token",
            "refresh_token=$offline_token",
            "scope=offline_access openid",
        ],
        "&",
    )
    io = IOBuffer()
    Downloads.request(
        IAM_URL;
        method = "POST",
        input = IOBuffer(form),
        headers = ["Content-Type" => "application/x-www-form-urlencoded"],
        output = io,
    )
    return String(JSON3.read(String(take!(io))).access_token)
end

stac_time(t::Dates.DateTime) = Dates.format(t, "yyyy-mm-ddTHH:MM:SSZ")

"""
    granule_urls(t0, t1)

.h5 download URLs for every ACM_CLP granule starting in [`t0`, `t1`].
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
        io = IOBuffer()
        Downloads.download("$SEARCH_URL?$query", io)
        page = JSON3.read(String(take!(io)))
        for item in page.features
            push!(urls, String(item.assets.enclosure_h5.href))
        end
        start_record += length(page.features)
        (isempty(page.features) || start_record > page.numberMatched) && break
    end
    return urls
end

mkpath(GRANULE_DIR)
urls = granule_urls(START_DATE, END_DATE)
@info "Found $(length(urls)) granules"

headers = ["Authorization" => "Bearer $(access_token(OFFLINE_TOKEN))"]
for url in urls
    dest = joinpath(GRANULE_DIR, basename(url))
    if isfile(dest)
        @info "Skipping $(basename(dest)) (already exists)"
        continue
    end
    @info "Downloading $(basename(dest))"
    Downloads.download(url, dest; headers, progress = download_rate_callback())
end

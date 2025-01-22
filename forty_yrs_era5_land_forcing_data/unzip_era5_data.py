import zipfile
import os

def unzip_era_5_files():
    # Get all directories starting eith era_5_*
    era_5_dirs = []
    for (_, dirs, _) in os.walk("."):
        for directory in dirs:
            if directory.startswith("era_5"):
                era_5_dirs.append(directory)
    # Get all the files in the directory in a list
    for directory in era_5_dirs:
        # Get all files
        only_files = [os.path.join(directory, f) for f in os.listdir(directory) if os.path.isfile(os.path.join(directory, f))]

        # Filter to get zip files whose names start with "era_5_focing_data_"
        only_zips = [f for f in only_files if os.path.basename(f).startswith("era5_forcing_data") and os.path.basename(f).endswith(".zip")]
        for zip_file in only_zips:
            # Get the file name excluding .zip at the end
            file_name_without_zip = zip_file[:-4]
            zipdata = zipfile.ZipFile(zip_file)
            zipinfos = zipdata.infolist()
            for zipinfo in zipinfos:
                file_name = zipinfo.filename
                # Rename files extracted
                if "avg" in file_name:
                    desired_file_name = file_name_without_zip + "_rate.nc"
                elif "instant" in file_name:
                    desired_file_name = file_name_without_zip + "_inst.nc"
                else:
                    raise FileExistsError("A file exists in the zip file that is not expected!")
                zipinfo.filename = desired_file_name
                zipdata.extract(zipinfo)

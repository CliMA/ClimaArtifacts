
<!-- Make sure to pick an unique name for your artifact -->
<!-- The easiest way to generate an artifact is using ClimaArtifactsHelper -->
<!-- ClimaArtifactsHelper generates ids and files for you -->

Checklist:
- [ ] I created a new folder `$artifact_name`
  - [ ] I added a `README.md` in that that folder that
    - [ ] describes the data and processing done to it
    - [ ] lists the sources of the raw data
    - [ ] lists the required citation, licenses
  - [ ] If applicable (e.g., for Creative Commons), I added a `LICENSE` file
  - [ ] I added the scripts that retrieve, process, and produce the artifact
  - [ ] I added the environment used for such scripts (typically, `Project.toml`
        and `Manifest.toml`)
  - [ ] I added the `OutputArtifacts.toml` file containing the information
        needed for package developers to add `$artifact_name` to their package
- [ ] I uploaded the artifact folder to the Caltech cluster (in
      `/resnick/groups/esm/ClimaArtifacts/artifacts/$artifact_name`)
- [ ] I added the relevant code to the `Overides.toml` on the Caltech Cluster
      (in `/resnick/groups/esm/ClimaArtifacts/artifacts/Overrides.toml`)
- [ ] I added a link to the main `README.md` to point to the new artifact

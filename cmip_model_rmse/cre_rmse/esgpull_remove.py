# Script copied and modified from this gist:
# https://gist.github.com/AtefBN/0293975cb7c57f12dd15e0c2029872b5 from this
# discussion: https://github.com/ESGF/esgf-download/issues/61
from esgpull import Esgpull, Query
from esgpull.models import FileStatus
import sys

def esgpull_remove(esgpull_dir, query_id):
    """Remove the files corresponding to bad datanodes from the esgpull database."""
    esg = Esgpull(esgpull_dir)
    query = esg.graph.get(query_id)
    missing_files = [f for f in query.files if f.status != FileStatus.Done]
    esg.db.delete(*missing_files)
    return None

if __name__ == "__main__":
    query_id = str(sys.argv[1])
    if len(sys.argv) <= 1:
        esgpull_dir = "cmip_download_esgpull"
    else:
        esgpull_dir = str(sys.argv[2])
    esgpull_remove(esgpull_dir, query_id)

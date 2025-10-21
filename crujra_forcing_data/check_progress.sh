#!/bin/bash
# Monitor artifact creation progress

echo "=== CRUJRA Artifact Creation Progress ==="
echo "Date: $(date)"
echo ""

# Check if process is running
PROC=$(ps aux | grep "[j]ulia.*create_artifact" | wc -l)
if [ $PROC -gt 0 ]; then
    echo "✓ Julia process is RUNNING"
    ps aux | grep "[j]ulia.*create_artifact" | awk '{print "  PID:", $2, "CPU:", $3"%", "MEM:", $4"%", "TIME:", $10}'
else
    echo "✗ Julia process is NOT running"
fi
echo ""

# Check output directory
OUTPUT_DIR="/home/renatob/data/crujra_forcing_data_artifact"
if [ -d "$OUTPUT_DIR" ]; then
    echo "Output directory: $OUTPUT_DIR/"
    FILES=$(ls $OUTPUT_DIR/*.nc 2>/dev/null | wc -l)
    echo "  Files created: $FILES / 123"
    if [ $FILES -gt 0 ]; then
        echo "  Latest file:"
        ls -lht $OUTPUT_DIR/*.nc 2>/dev/null | head -1
        echo "  Total size:"
        du -sh $OUTPUT_DIR/ 2>/dev/null
    fi
else
    echo "Output directory not yet created"
fi
echo ""

# Check log files
if [ -f "create_artifact.log" ]; then
    echo "Last 10 lines of log:"
    tail -10 create_artifact.log
elif [ -f "nohup.out" ]; then
    echo "Last 10 lines of nohup.out:"
    tail -10 nohup.out
fi

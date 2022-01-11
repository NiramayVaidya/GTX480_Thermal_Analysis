# Prerequisities for running this automation script-
# 1. a bash session has been started (required for both conda and gpgpu-sim
# compilation)
# 2. required conda env has been activated (conda activate <env_name>)
# 3. required conda packages have been installed (including matplotlib)
# 4. all the python scripts in the scripts folder within the hotspot repo are 
# pointing to the python/python3 binary from the activated conda env
# 5. this current folder contains all the required files for hotspot to
# simulate correctly (.config, .lcf, .materials and .flp (multiple))
# 6. under HotSpot scripts, in grid_thermal_map.py, at line num 51,
# figsize=(15, 15) during fig creation via subplots has been added (required for
# more clarity in the heat map image with respect to visibility of all the
# components, specially for the more detailed floorplan 1

if (( $# < 3 )); then
	echo "Invalid number of parameters"
	echo "Usage: source ./automate.sh <tensor_dimension> <layer_id> <power_report_log_file>"
	echo "tensor_dimension > 0"
	echo "layer_id = 0/2"
	return
fi

if (( $1 < 0 )); then
	echo "Invalid tensor dimension"
	echo "tensor_dimension > 0"
	return
fi

# Only 0 and 2 layer ids are allowed as input since only these layers are
# silicon layers
if (( $2 != 0 && $2 != 2 )); then
	echo "Invalid layer id"
	echo "layer_id = 0/2"
	return
fi

if [ `ls -1 $3 2>/dev/null | wc -l ` -ne 1 ]; then
	echo "Power report log file not found"
	return
fi

echo "Generating the required folder structure if not present..."
mkdir -p generated_files
mkdir -p generated_files/hotspot_outputs
mkdir -p generated_files/hotspot_outputs/steady
mkdir -p generated_files/hotspot_outputs/transient
echo "Required folder structure generated"

# Deleting the previous ptrace file, if any
echo "Deleting the previously generated ptrace file if it exists..."
if [ `ls -1 fermi.ptrace 2>/dev/null | wc -l ` -gt 0 ]; then
	rm -f fermi.ptrace
fi
echo "Deletion done"

# Generating the ptrace file from the power report
echo "Generating the ptrace for HotSpot from the power report..."
python3 power_report_to_ptrace_converter.py $3

if [ `ls -1 fermi.ptrace 2>/dev/null | wc -l ` -ne 1 ]; then
	echo "Generation of the ptrace file failed"
	return
fi
echo "Generation done"

# Running HotSpot
echo "Running hotspot to generate steady and transient temperature results..."
HotSpot/hotspot -c fermi.config -p fermi.ptrace -grid_layer_file fermi.lcf -materials_file fermi.materials -model_type grid -detailed_3D on -steady_file generated_files/hotspot_outputs/steady/fermi.steady -grid_steady_file generated_files/hotspot_outputs/steady/fermi.grid.steady

HotSpot/hotspot -c fermi.config -p fermi.ptrace -grid_layer_file fermi.lcf -materials_file fermi.materials -model_type grid -detailed_3D on -o generated_files/hotspot_outputs/transient/fermi.ttrace -grid_transient_file generated_files/hotspot_outputs/transient/fermi.grid.ttrace
echo "Generated steady and transient grid temperature results for all layers"

# Creating output folder for given matrix dimension and layer id
echo "Creating the output folder for the provided matrix dimension and layer id..."
mkdir -p generated_files/hotspot_outputs/tensor_size_$1_layer_$2
echo "Creation done"

# Copying the steady state temperature files to this folder
echo "Copying the steady state temperature (component and grid block wise) files to this folder..."
cp generated_files/hotspot_outputs/steady/fermi.steady generated_files/hotspot_outputs/tensor_size_$1_layer_$2/
cp generated_files/hotspot_outputs/steady/fermi.grid.steady generated_files/hotspot_outputs/tensor_size_$1_layer_$2/
echo "Copying done"

# Running HotSpot scripts for heat map image generation
echo "Running hotspot scripts for generation of the heat map image..."
HotSpot/scripts/split_grid_steady.py generated_files/hotspot_outputs/steady/fermi.grid.steady 4 8 8

if (( $2 == 0 )); then
	HotSpot/scripts/grid_thermal_map.py fermi_floorplan1.flp generated_files/hotspot_outputs/steady/fermi_layer0.grid.steady 8 8 generated_files/hotspot_outputs/tensor_size_$1_layer_0/layer0.png
	HotSpot/scripts/grid_thermal_map.pl fermi_floorplan1.flp generated_files/hotspot_outputs/steady/fermi_layer0.grid.steady 8 8 > generated_files/hotspot_outputs/tensor_size_$1_layer_0/layer0.svg
else
	HotSpot/scripts/grid_thermal_map.py fermi_floorplan2.flp generated_files/hotspot_outputs/steady/fermi_layer2.grid.steady 8 8 generated_files/hotspot_outputs/tensor_size_$1_layer_2/layer2.png
	HotSpot/scripts/grid_thermal_map.pl fermi_floorplan2.flp generated_files/hotspot_outputs/steady/fermi_layer2.grid.steady 8 8 > generated_files/hotspot_outputs/tensor_size_$1_layer_2/layer2.svg
fi
echo "Heap map image generation done"

# Storing current run's tensor dimension
echo $1 > prev_tensor_dim.in

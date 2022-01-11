# Prerequisities for running this automation script-
# 1. a bash session has been started (required for both conda and gpgpu-sim
# compilation)
# 2. required conda env has been activated (conda activate <env_name>)
# 3. required conda packages have been installed (including matplotlib)
# 4. all the python scripts in the scripts folder within the hotspot repo are 
# pointing to the python/python3 binary from the activated conda env
# 5. required env vars have been exported (PATH, LD_LIBRARY_PATH, 
# CUDA_INSTALL_PATH)
# 6. make clean for gpgpu-sim has been done
# 7. source setup_environment for gpgpu-sim has been executed
# 8. make -j8 for gpgpu-sim has been executed (gpgpu-sim has been compiled/built)
# 9. this script has been placed in a folder which has the gpgpu-sim and hotspot
# repos
# 10. this current folder contains all the 3 files from the SM2_GTX480 gpgpu-sim
# folder (config_fermi, gpgpusim.config, gpuwattch xml)
# 11. this current folder contains all the required files for hotspot to
# simulate correctly (.config, .lcf, .materials and .flp (multiple))
# 12. this current folder has the mat_mul.cu kernel file
# 13. under HotSpot scripts, in grid_thermal_map.py, at line num 51,
# figsize=(15, 15) during fig creation via subplots has been added (required for
# more clarity in the heat map image with respect to visibility of all the
# components, specially for the more detailed floorplan 1

if (( $# < 2 )); then
	echo "Invalid number of parameters"
	echo "Usage: source ./automate.sh <tensor_dimension> <layer_id>"
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

# Checking if previous run's tensor dimension is available, if not, store dummy
# value
if [ `ls -1 prev_tensor_dim.in 2>/dev/null | wc -l ` -ne 1 ]; then
    echo "-1" > prev_tensor_dim.in
fi

# Getting previous run's tensor dimension
prev_tensor_dim="$(cat prev_tensor_dim.in)"

echo $prev_tensor_dim

# Checking if current run's tensor dimension is equal to that of the previous
# run, if no, then re-execute kernel, if yes, then just re-execute HotSpot
if (( $1 != $prev_tensor_dim )); then
	echo "Provided tensor dimension for the current run not same as that provided for the previous run, kernel needs to be re-executed"

	echo "Generating the required folder structure if not present..."
	mkdir -p generated_files
	mkdir -p generated_files/app_cuda_versions
	mkdir -p generated_files/cuobjdumps
	mkdir -p generated_files/ptx_files
	mkdir -p generated_files/ptxas_files
	mkdir -p generated_files/gpgpusim_power_report_logs
	mkdir -p generated_files/kernel_outputs
	mkdir -p generated_files/hotspot_outputs
	mkdir -p generated_files/hotspot_outputs/steady
	mkdir -p generated_files/hotspot_outputs/transient
	echo "Required folder structure generated"

	# Generated files in this case only refer to the gpgpusim related files, not the
	# Hotspot related files (Hotspot generated files for the previous run already
	# reside in the folder structure and will get replaced by current run's
	# generated files, except the result ones i.e. the heat map images and the main
	# files containing the steady state temperatures for all the layers' components
	# and temperatures for all the layers according to the grid blocks)

	# Previous to previous run's generated files are stored in the folder structure,
	# which need to be deleted to be replaced with previous run's generated files
	# which are in the current directory, which in turn will get replaced by the
	# current run's generated files
	# The objective is to always keep intact previous run's generated files upon
	# executing a new run
	echo "Deleting previous to previous run's generated files..."
	if [ `ls -1 generated_files/app_cuda_versions/* 2>/dev/null | wc -l ` -gt 0 ]; then
		rm -f generated_files/app_cuda_versions/*
	fi

	if [ `ls -1 generated_files/cuobjdumps/* 2>/dev/null | wc -l ` -gt 0 ]; then
		rm -f generated_files/cuobjdumps/*
	fi

	if [ `ls -1 generated_files/ptx_files/* 2>/dev/null | wc -l ` -gt 0 ]; then
		rm -f generated_files/ptx_files/*
	fi

	if [ `ls -1 generated_files/ptxas_files/* 2>/dev/null | wc -l ` -gt 0 ]; then
		rm -f generated_files/ptxas_files/*
	fi

	if [ `ls -1 generated_files/gpgpusim_power_report_logs/* 2>/dev/null | wc -l ` -gt 0 ]; then
		rm -f generated_files/gpgpusim_power_report_logs/*
	fi
	echo "Deleted previous to previous run's generated files"

	echo "Moving previous run's generated files to the folder structure..."
	if [ `ls -1 _app_cuda_version_* 2>/dev/null | wc -l ` -gt 0 ]; then
		mv _app_cuda_version_* generated_files/app_cuda_versions/
	fi

	if [ `ls -1 _cuobjdump_list_ptx_* 2>/dev/null | wc -l ` -gt 0 ]; then
		mv _cuobjdump_list_ptx_* generated_files/cuobjdumps/
	fi

	if [ `ls -1 *.ptx 2>/dev/null | wc -l ` -gt 0 ]; then
		mv *.ptx generated_files/ptx_files/
	fi

	if [ `ls -1 *.ptxas 2>/dev/null | wc -l ` -gt 0 ]; then
		mv *.ptxas generated_files/ptxas_files/
	fi

	if [ `ls -1 gpgpusim_power_report__* 2>/dev/null | wc -l ` -gt 0 ]; then
		mv gpgpusim_power_report__* generated_files/gpgpusim_power_report_logs/
	fi
	echo "Moved previous run's generated files to the folder structure"

	# Getting the matrix dimension line number in the mat mul kernel
	tensor_dimension_lineno="$(grep -n -- "#define N" mat_mul.cu | cut -d ":" -f 1)"

	# Replacing it with the desired dimension passed in through cmd
	sed -i "${tensor_dimension_lineno}s/.*/#define N $1/" mat_mul.cu

	# Compiling the kernel
	echo "Compiling the mat mul kernel..."
	nvcc mat_mul.cu -lcudart -o mat_mul.o
	echo "Compilation done"

	libcudart_so_location="$(realpath gpgpu-sim_distribution/lib/gcc-4.8.5/cuda-9010/release/libcudart.so.9.1)"

	# Checking if the correct libcudart lib is linked to the kernel executable
	if [ `ldd mat_mul.o | grep "libcudart.so.9.1 => ${libcudart_so_location}" | wc -l ` -ne 1 ]; then
		echo "Compilation/Build of gpgpu-sim wasn't successful, run make -j8 again in the gpgpu-sim repo and retry running this script"
		return
	fi

	kernel_output_file="generated_files/kernel_outputs/mat_mul_$1.out"

	# Executing the kernel
	echo "Executing the kernel..."
	./mat_mul.o > $kernel_output_file
	echo "Execution done"

	gpgpusim_power_report_log=(*.log)

	# Deleting the previous ptrace file, if any
	echo "Deleting the previously generated ptrace file if it exists..."
	if [ `ls -1 fermi.ptrace 2>/dev/null | wc -l ` -gt 0 ]; then
		rm -f fermi.ptrace
	fi
	echo "Deletion done"

	# Generating the ptrace file from the power report
	echo "Generating the ptrace for HotSpot from the power report..."
	python3 power_report_to_ptrace_converter.py $gpgpusim_power_report_log

	if [ `ls -1 fermi.ptrace 2>/dev/null | wc -l ` -ne 1 ]; then
		echo "Generation of the ptrace file failed"
		return
	fi
	echo "Generation done"
else
	echo "Provided tensor dimension for the current run same as that provided for the previous run, only hotspot needs to be re-executed"
fi

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

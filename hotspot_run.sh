# Running HotSpot
echo "Running hotspot to generate steady and transient temperature results..."
HotSpot/hotspot -c fermi.config -p fermi.ptrace -grid_layer_file fermi.lcf -materials_file fermi.materials -model_type grid -detailed_3D on -steady_file fermi.steady -grid_steady_file fermi.grid.steady

HotSpot/hotspot -c fermi.config -p fermi.ptrace -grid_layer_file fermi.lcf -materials_file fermi.materials -model_type grid -detailed_3D on -o fermi.ttrace -grid_transient_file fermi.grid.ttrace
echo "Generated steady and transient grid temperature results for all layers"

# Creating output folder for given matrix dimension and layer id
# echo "Creating the output folder for the provided matrix dimension and layer id..."
# mkdir -p generated_files/hotspot_outputs/tensor_size_$1_layer_$2
# echo "Creation done"

# Copying the steady state temperature files to this folder
# echo "Copying the steady state temperature (component and grid block wise) files to this folder..."
# cp generated_files/hotspot_outputs/steady/fermi.steady generated_files/hotspot_outputs/tensor_size_$1_layer_$2/
# cp generated_files/hotspot_outputs/steady/fermi.grid.steady generated_files/hotspot_outputs/tensor_size_$1_layer_$2/
# echo "Copying done"

# Running HotSpot scripts for heat map image generation
echo "Running hotspot scripts for generation of the heat map image..."
HotSpot/scripts/split_grid_steady.py fermi.grid.steady 4 8 8

# if (( $2 == 0 )); then
HotSpot/scripts/grid_thermal_map.py fermi_floorplan1.flp fermi_layer0.grid.steady 8 8 layer0.png
HotSpot/scripts/grid_thermal_map.pl fermi_floorplan1.flp fermi_layer0.grid.steady 8 8 > layer0.svg
# else
# 	HotSpot/scripts/grid_thermal_map.py floorplan2.flp generated_files/hotspot_outputs/steady/example_layer2.grid.steady 8 8 generated_files/hotspot_outputs/tensor_size_$1_layer_2/layer2.png
# 	HotSpot/scripts/grid_thermal_map.pl floorplan2.flp generated_files/hotspot_outputs/steady/example_layer2.grid.steady 8 8 > generated_files/hotspot_outputs/tensor_size_$1_layer_2/layer2.svg
# fi
echo "Heap map image generation done"

read_db lp_final2.db
foreach p {load_data_i\[0\] load_data_i\[2\] load_data_i\[12\] load_addr_i\[0\] gpio_o\[0\]} {
  set po [get_db ports $p]
  puts "PINQ $p : side=[get_db $po .side] layer=[get_db $po .physical_pins.layer_shapes.layer.name] rect=[get_db $po .physical_pins.layer_shapes.shapes.rect] net=[get_db $po .net.name]"
}
exit

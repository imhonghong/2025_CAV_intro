// bind_traffic.sv
bind TRAFFIC traffic_assert u_traffic_assert (
  .clk   (clk),
  .rst   (rst),
  .Road1_G(Road1_G), .Road1_Y(Road1_Y), .Road1_R(Road1_R),
  .Road2_G(Road2_G), .Road2_Y(Road2_Y), .Road2_R(Road2_R),
  .Walk_G(Walk_G),   .Walk_R(Walk_R)
);
//Optimized - using hull() to reduce geometry count
$fn = 3;
difference(){
union(){
translate([-4700,0,50])
rotate([0,90,0])
cylinder(600, d1=200, d2=200, center=true);
translate([-4250.0006,0,42.629])
rotate([0,90,0])
cylinder(299.9988, d1=200, d2=141.0321, center=true);
translate([-3952.801,28.8462,34.1912])
rotate([-11.0875,90,0])
cylinder(300, d1=141.0321, d2=132.4974, center=true);
translate([-3658.2636,29.5542,31.1068])
rotate([10.812,90,0])
cylinder(300, d1=132.4974, d2=116.3568, center=true);
translate([-3660.1944,94.5294,31.1195])
rotate([-14.2161,90,0])
cylinder(300, d1=132.4974, d2=116.4586, center=true);
translate([-3360.9277,0.80996,27.2109])
rotate([0.23153,90,0])
cylinder(300, d1=116.3568, d2=101.33, center=true);
translate([-3361.6604,-13.4047,27.2153])
rotate([5.6704,90,0])
cylinder(300, d1=116.3568, d2=101.3655, center=true);
translate([-3368.2885,163.5829,27.2682])
rotate([-12.4024,90,0])
cylinder(300, d1=116.4586, d2=101.6866, center=true);
translate([-3086.5135,-39.6585,23.7446])
rotate([5.1896,90,0])
cylinder(252.7982, d1=101.3655, d2=88.5913, center=true);
translate([-3072.5469,210.8591,23.7073])
rotate([-5.7621,90,0])
cylinder(300, d1=101.6866, d2=87.9719, center=true);
translate([-3085.7807,-25.4439,23.7402])
rotate([11.5818,90,0])
cylinder(255.4985, d1=101.33, d2=88.5913, center=true);
translate([-2938.8348,-55.5589,21.347])
rotate([11.5818,90,0])
cylinder(44.5015, d1=88.5913, d2=82.1846, center=true);
translate([-2778.3244,-117.1117,19.7203])
rotate([22.3691,90,0])
cylinder(300, d1=82.1846, d2=75.5774, center=true);
translate([-2779.5805,268.8529,20.45])
rotate([-16.6322,90,0])
cylinder(300, d1=87.9719, d2=75.6277, center=true);
translate([-2499.751,-228.4099,17.5711])
rotate([21.1872,90,0])
cylinder(300, d1=75.5774, d2=64.991, center=true);
translate([-2497.966,370.8317,17.5693])
rotate([-23.1807,90,0])
cylinder(300, d1=75.6277, d2=64.9268, center=true);
translate([-2500.8169,246.4845,17.5821])
rotate([25.8075,90,0])
cylinder(300, d1=75.6277, d2=65.0294, center=true);
translate([-2210.6873,-298.0641,15.0223])
rotate([5.9088,90,0])
cylinder(300, d1=64.991, d2=55.1874, center=true);
translate([-2317.0654,-426.3792,15.4558])
rotate([73.4113,90,0])
cylinder(300, d1=64.991, d2=58.6553, center=true);
translate([-2213.5899,462.1546,15.0258])
rotate([-12.4265,90,0])
cylinder(300, d1=64.9268, d2=55.2799, center=true);
translate([-2216.1838,170.1506,15.049])
rotate([4.2175,90,0])
cylinder(300, d1=65.0294, d2=55.3626, center=true);
translate([-1925.3828,-376.5646,12.7348])
rotate([24.8593,90,0])
cylinder(300, d1=55.1874, d2=46.6911, center=true);
translate([-1970.6765,-194.1159,12.8936])
rotate([-52.7434,90,0])
cylinder(300, d1=55.1874, d2=47.9617, center=true);
translate([-2160.665,-668.1189,14.0335])
rotate([40.7847,90,0])
cylinder(300, d1=58.6553, d2=53.613, center=true);
translate([-2140.0162,-637.0978,13.9536])
rotate([26.5137,90,0])
cylinder(300, d1=58.6553, d2=52.9736, center=true);
translate([-1921.048,528.6037,12.7314])
rotate([-13.168,90,0])
cylinder(300, d1=55.2799, d2=46.5711, center=true);
translate([-1928.6485,552.1397,12.7577])
rotate([-22.626,90,0])
cylinder(300, d1=55.2799, d2=46.7817, center=true);
translate([-1917.9334,139.089,12.7309])
rotate([7.6738,90,0])
cylinder(300, d1=55.3626, d2=46.485, center=true);
translate([-1640.8247,-418.1614,10.7595])
rotate([-8.2261,90,0])
cylinder(300, d1=46.6911, d2=39.3846, center=true);
translate([-1743.5454,-12.1483,11.2312])
rotate([-24.6569,90,0])
cylinder(300, d1=47.9617, d2=41.8876, center=true);
translate([-1916.0738,-839.1417,12.5058])
rotate([29.1392,90,0])
cylinder(300, d1=53.613, d2=46.4336, center=true);
translate([-1895.425,-808.1206,12.4259])
rotate([43.3155,90,0])
cylinder(303.3783, d1=52.9736, d2=46.4336, center=true);
translate([-1638.5025,619.4746,10.7639])
rotate([-3.6317,90,0])
cylinder(303.9917, d1=46.7817, d2=39.3298, center=true);
translate([-1619.6133,129.1014,10.6715])
rotate([-3.8388,90,0])
cylinder(300, d1=46.485, d2=38.8867, center=true);
translate([-1630.9019,595.9386,10.7376])
rotate([-12.9615,90,0])
cylinder(295.7147, d1=46.5711, d2=39.3298, center=true);
translate([-1484.7238,629.583,9.4002])
rotate([-12.9615,90,0])
cylinder(4.2853, d1=39.3298, d2=35.8717, center=true);
translate([-1344.4717,-371.6661,9.0499])
rotate([-9.607,90,0])
cylinder(300, d1=39.3846, d2=33.0147, center=true);
translate([-1538.586,94.7866,10.0968])
rotate([-32.8733,90,0])
cylinder(163.444, d1=41.8876, d2=38.8867, center=true);
translate([-1638.7195,-945.1223,10.7211])
rotate([12.6858,90,0])
cylinder(300, d1=46.4336, d2=39.3349, center=true);
translate([-1344.158,687.717,8.61])
rotate([-22.6037,90,0])
cylinder(300, d1=35.8717, d2=33.0087, center=true);
translate([-1321.5337,160.8846,8.9326])
rotate([-8.3337,90,0])
cylinder(300, d1=38.8867, d2=32.5745, center=true);
translate([-1322.0813,164.3407,8.9339])
rotate([-9.6703,90,0])
cylinder(300, d1=38.8867, d2=32.5849, center=true);
translate([-1047.7426,-365.3097,7.6148])
rotate([7.1526,90,0])
cylinder(300, d1=33.0147, d2=27.9039, center=true);
translate([-1056.9996,-291.6909,7.6324])
rotate([-21.4863,90,0])
cylinder(300, d1=33.0147, d2=28.0442, center=true);
translate([-1351.9124,-1030.6798,9.0618])
rotate([20.535,90,0])
cylinder(300, d1=39.3349, d2=33.1592, center=true);
translate([-1357.4839,-912.4676,9.0753])
rotate([-25.9318,90,0])
cylinder(300, d1=39.3349, d2=33.2679, center=true);
translate([-1072.7975,814.9561,7.6619])
rotate([-27.6394,90,0])
cylinder(300, d1=33.0087, d2=28.2864, center=true);
translate([-1055.8948,753.3923,7.6295])
rotate([-3.0657,90,0])
cylinder(300, d1=33.0087, d2=28.0274, center=true);
translate([-1025.4676,209.0728,7.5182])
rotate([-10.1553,90,0])
cylinder(300, d1=32.5745, d2=27.5714, center=true);
translate([-1056.7652,282.8441,7.5782])
rotate([-38.4655,90,0])
cylinder(300, d1=32.5849, d2=28.0406, center=true);
translate([-1030.271,231.7369,7.5284])
rotate([-16.3395,90,0])
cylinder(300, d1=32.5849, d2=27.6425, center=true);
translate([-754.9578,-341.8227,6.5136])
rotate([-16.3254,90,0])
cylinder(300, d1=27.9039, d2=24.205, center=true);
translate([-764.2147,-268.204,6.5311])
rotate([11.602,90,0])
cylinder(312.8094, d1=28.0442, d2=24.205, center=true);
translate([-1061.4486,-1082.0828,7.6589])
rotate([-0.46366,90,0])
cylinder(300, d1=33.1592, d2=28.112, center=true);
translate([-1074.4691,-823.1831,7.6975])
rotate([-9.0867,90,0])
cylinder(300, d1=33.2679, d2=28.3123, center=true);
translate([-789.9247,882.8194,6.5974])
rotate([0.65798,90,0])
cylinder(300, d1=28.2864, d2=24.4927, center=true);
translate([-773.0221,821.2556,6.565])
rotate([-24.2105,90,0])
cylinder(291.8441, d1=28.0274, d2=24.4927, center=true);
translate([-729.0119,216.6293,6.4303])
rotate([7.235,90,0])
cylinder(300, d1=27.5714, d2=23.8713, center=true);
translate([-801.1999,434.6607,6.5828])
rotate([-22.9587,90,0])
cylinder(300, d1=28.0406, d2=24.6218, center=true);
translate([-733.2677,235.8373,6.4392])
rotate([13.9776,90,0])
cylinder(315.4639, d1=27.6425, d2=23.8713, center=true);
translate([-761.5054,-1084.8125,6.5359])
rotate([1.5065,90,0])
cylinder(300, d1=28.112, d2=24.1752, center=true);
translate([-815.5754,-1196.2266,6.6127])
rotate([50.2687,90,0])
cylinder(300, d1=28.112, d2=24.7892, center=true);
translate([-810.3604,-704.3831,6.6301])
rotate([-39.3512,90,0])
cylinder(300, d1=28.3123, d2=24.7281, center=true);
translate([-827.0783,-687.0446,6.6547])
rotate([-48.5611,90,0])
cylinder(300, d1=28.3123, d2=24.9252, center=true);
translate([-500.1972,826.5676,5.7868])
rotate([21.3171,90,0])
cylinder(300, d1=24.4927, d2=21.8014, center=true);
translate([-517.2223,967.3622,5.8023])
rotate([-35.1068,90,0])
cylinder(300, d1=24.4927, d2=21.9261, center=true);
translate([-430.5958,208.5419,5.6508])
rotate([-4.1302,90,0])
cylinder(300, d1=23.8713, d2=21.335, center=true);
translate([-517.9927,61.2485,5.7254])
rotate([65.496,90,0])
cylinder(300, d1=23.8713, d2=21.9319, center=true);
translate([-523.0554,546.9535,5.824])
rotate([-21.0112,90,0])
cylinder(300, d1=24.6218, d2=21.9698, center=true);
translate([-213.0341,-115.9788,5.1644])
rotate([-6.1664,90,0])
cylinder(300, d1=20.9884, d2=20.3268, center=true);
translate([-463.95,-1062.0707,5.7156])
rotate([-10.2476,90,0])
cylinder(300, d1=24.1752, d2=21.5498, center=true);
translate([-571.7914,-1286.6074,5.8929])
rotate([-9.5851,90,0])
cylinder(300, d1=24.7892, d2=22.354, center=true);
translate([-669.9225,-1453.085,6.0026])
rotate([70.62,90,0])
cylinder(300, d1=24.7892, d2=23.2313, center=true);
translate([-578.5905,-557.9817,5.9169])
rotate([-6.3532,90,0])
cylinder(300.2731, d1=24.9252, d2=22.4103, center=true);
translate([-211.6569,790.952,5.2655])
rotate([-7.2438,90,0])
cylinder(300, d1=21.8014, d2=20.3226, center=true);
translate([-245.3377,1069.3633,5.2949])
rotate([-6.0217,90,0])
cylinder(300, d1=21.9261, d2=20.4334, center=true);
translate([-131.7123,204.5953,5.1905])
rotate([5.6433,90,0])
cylinder(300, d1=21.335, d2=20.189, center=true);
translate([-159.6081,131.2116,5.1898])
rotate([35.9839,90,0])
cylinder(300, d1=21.335, d2=20.1834, center=true);
translate([-417.3101,-109.2807,5.4619])
rotate([41.504,90,0])
cylinder(102.7336, d1=21.9319, d2=21.7636, center=true);
translate([-299.1446,611.3038,5.3268])
rotate([-7.1803,90,0])
cylinder(169.0947, d1=21.9698, d2=20.6443, center=true);
translate([-561.8726,-575.3201,5.8923])
rotate([-14.3728,90,0])
cylinder(273.5552, d1=24.7281, d2=22.4103, center=true);
translate([-416.5674,-538.0857,5.4575])
rotate([-14.3728,90,0])
cylinder(26.4448, d1=22.4103, d2=21.2494, center=true);
translate([-494.9233,-221.4895,5.7461])
rotate([-33.9562,90,0])
cylinder(279.8969, d1=24.205, d2=21.7636, center=true);
translate([-370.5036,-137.7057,5.344])
rotate([-33.9562,90,0])
cylinder(20.1031, d1=21.7636, d2=20.9884, center=true);
translate([-287.86,696.9549,5.3057])
rotate([45.9635,90,0])
cylinder(208.8849, d1=21.8014, d2=20.6443, center=true);
translate([-183.5924,589.1204,5.1109])
rotate([45.9635,90,0])
cylinder(91.1151, d1=20.6443, d2=20.2427, center=true);
translate([-166.4999,-1042.2475,5.2187])
rotate([2.6221,90,0])
cylinder(300, d1=21.5498, d2=20.1996, center=true);
translate([-297.7842,-1342.8616,5.3741])
rotate([32.7885,90,0])
cylinder(300, d1=22.354, d2=20.6385, center=true);
translate([-512.6857,-1699.2373,5.6405])
rotate([44.2409,90,0])
cylinder(300, d1=23.2313, d2=21.8925, center=true);
translate([-255.4561,-512.3027,5.2149])
rotate([-8.6273,90,0])
cylinder(300, d1=21.2494, d2=20.4699, center=true);
translate([82.6983,773.6099,5.1686])
rotate([13.9872,90,0])
cylinder(300, d1=20.3226, d2=21.0259, center=true);
translate([64.0845,889.7818,5.1411])
rotate([-32.1931,90,0])
cylinder(300, d1=20.3226, d2=20.8062, center=true);
translate([-33.5783,464.2055,5.0431])
rotate([37.9102,90,0])
cylinder(300, d1=20.2427, d2=20.1023, center=true);
translate([-51.3397,445.0917,5.0361])
rotate([47.8893,90,0])
cylinder(300, d1=20.2427, d2=20.0461, center=true);
translate([50.9968,1114.1384,5.1571])
rotate([-11.1627,90,0])
cylinder(300, d1=20.4334, d2=20.8235, center=true);
translate([162.0183,230.2433,5.2111])
rotate([-15.6238,90,0])
cylinder(300, d1=20.189, d2=21.5001, center=true);
translate([49.4555,12.6884,5.0506])
rotate([19.1148,90,0])
cylinder(185.6062, d1=20.1834, d2=20.2217, center=true);
translate([36.6199,-58.7836,5.0686])
rotate([-22.2295,90,0])
cylinder(217.1859, d1=20.3268, d2=20.2217, center=true);
translate([175.4713,-2.0361,5.1454])
rotate([-22.2295,90,0])
cylinder(82.8141, d1=20.2217, d2=20.9419, center=true);
translate([361.6868,38.7238,5.5044])
rotate([-9.6308,90,0])
cylinder(300, d1=20.9419, d2=23.0931, center=true);
translate([117.0095,-981.0415,5.1688])
rotate([-26.987,90,0])
cylinder(300, d1=20.1996, d2=21.1504, center=true);
translate([-21.8324,-1417.3986,5.1489])
rotate([-2.5578,90,0])
cylinder(300, d1=20.6385, d2=20.5527, center=true);
translate([-59.6531,-1523.8387,5.127])
rotate([41.6804,90,0])
cylinder(300, d1=20.6385, d2=20.3775, center=true);
translate([-293.2499,-1903.6979,5.314])
rotate([41.7125,90,0])
cylinder(300, d1=21.8925, d2=20.6192, center=true);
translate([-255.7585,-1791.2363,5.2954])
rotate([-4.8387,90,0])
cylinder(300, d1=21.8925, d2=20.471, center=true);
translate([25.2865,-419.3767,5.1373])
rotate([-28.0019,90,0])
cylinder(300, d1=20.4699, d2=20.6283, center=true);
translate([26.0626,-420.856,5.1377])
rotate([-27.3638,90,0])
cylinder(300, d1=20.4699, d2=20.6316, center=true);
translate([377.4784,752.5566,5.538])
rotate([-5.8169,90,0])
cylinder(300, d1=21.0259, d2=23.278, center=true);
translate([334.6261,1013.0359,5.448])
rotate([-16.7933,90,0])
cylinder(300, d1=20.8062, d2=22.7776, center=true);
translate([119.2273,344.6152,5.0471])
rotate([38.5165,90,0])
cylinder(88.0832, d1=20.1023, d2=20.2742, center=true);
translate([80.026,305.4448,5.0329])
rotate([42.6655,90,0])
cylinder(83.7206, d1=20.0461, d2=20.2173, center=true);
translate([338.1941,1099.7759,5.4501])
rotate([17.2201,90,0])
cylinder(293.2135, d1=20.8235, d2=22.7776, center=true);
translate([456.4434,273.7617,5.6995])
rotate([-1.192,90,0])
cylinder(300, d1=21.5001, d2=24.0957, center=true);
translate([452.9814,238.4522,5.6948])
rotate([12.3917,90,0])
cylinder(300, d1=21.5001, d2=24.0582, center=true);
translate([421.5266,335.8371,5.6719])
rotate([17.6862,90,0])
cylinder(388.113, d1=21.2793, d2=24.0957, center=true);
translate([85.6237,253.517,5.0579])
rotate([-43.0908,90,0])
cylinder(186.4046, d1=20.189, d2=20.2742, center=true);
translate([195.1645,355.9905,5.1942])
rotate([-43.0908,90,0])
cylinder(113.5954, d1=20.2742, d2=21.2793, center=true);
translate([64.1838,233.4603,5.0508])
rotate([-43.0908,90,0])
cylinder(127.6869, d1=20.189, d2=20.2173, center=true);
translate([173.7245,335.9338,5.1871])
rotate([-43.0908,90,0])
cylinder(172.3131, d1=20.2173, d2=21.2793, center=true);
translate([655.4335,98.8132,6.1978])
rotate([-13.4913,90,0])
cylinder(300, d1=23.0931, d2=26.4892, center=true);
translate([399.7271,-896.1277,5.5786])
rotate([-6.4482,90,0])
cylinder(300, d1=21.1504, d2=23.4784, center=true);
translate([277.0748,-1427.5006,5.354])
rotate([6.4291,90,0])
cylinder(300, d1=20.5527, d2=22.2794, center=true);
translate([266.7989,-1467.6246,5.3442])
rotate([22.3007,90,0])
cylinder(300, d1=20.5527, d2=22.2012, center=true);
translate([228.9783,-1574.0648,5.3223])
rotate([-15.6638,90,0])
cylinder(366.8259, d1=20.3775, d2=22.2012, center=true);
translate([-54.0812,-2083.0147,5.1183])
rotate([32.009,90,0])
cylinder(300, d1=20.6192, d2=20.3275, center=true);
translate([43.5257,-1771.2124,5.1634])
rotate([-2.8168,90,0])
cylinder(300, d1=20.471, d2=20.836, center=true);
translate([42.3248,-1758.2674,5.1626])
rotate([-7.7842,90,0])
cylinder(300, d1=20.471, d2=20.8301, center=true);
translate([295.3967,-289.3961,5.3764])
rotate([-23.3931,90,0])
cylinder(300, d1=20.6283, d2=22.3832, center=true);
translate([296.1728,-290.8754,5.3769])
rotate([-24.0299,90,0])
cylinder(299.7686, d1=20.6316, d2=22.3832, center=true);
translate([673.2093,735.5602,6.2453])
rotate([12.3955,90,0])
cylinder(300, d1=23.278, d2=26.6845, center=true);
translate([674.7463,791.9268,6.2589])
rotate([-9.2718,90,0])
cylinder(300, d1=23.278, d2=26.7929, center=true);
translate([621.112,1102.0299,6.0031])
rotate([-17.7205,90,0])
cylinder(300, d1=22.7776, d2=25.247, center=true);
translate([748.9631,323.5605,6.4859])
rotate([-18.1309,90,0])
cylinder(300, d1=24.0957, d2=27.7916, center=true);
translate([750.7607,226.9054,6.2419])
rotate([-7.7705,90,0])
cylinder(305.3515, d1=24.0582, d2=25.8773, center=true);
translate([754.2227,262.215,6.2466])
rotate([5.6668,90,0])
cylinder(297.0753, d1=24.0957, d2=25.8773, center=true);
translate([903.4897,247.4035,6.6368])
rotate([5.6668,90,0])
cylinder(2.9247, d1=25.8773, d2=27.217, center=true);
translate([949.3544,109.7615,6.9574])
rotate([9.2248,90,0])
cylinder(300, d1=26.4892, d2=29.1703, center=true);
translate([695.0619,-846.0998,6.319])
rotate([-12.7804,90,0])
cylinder(300, d1=23.4784, d2=27.0736, center=true);
translate([562.6632,-1382.1751,5.9094])
rotate([-24.4654,90,0])
cylinder(300, d1=22.2794, d2=24.9956, center=true);
translate([552.9183,-1552.6755,5.9151])
rotate([10.8092,90,0])
cylinder(300, d1=22.2012, d2=25.1197, center=true);
translate([213.2622,-2215.9862,5.269])
rotate([20.8808,90,0])
cylinder(300, d1=20.3275, d2=21.8246, center=true);
translate([339.5451,-1746.8506,5.3205])
rotate([3.4272,90,0])
cylinder(297.7375, d1=20.8301, d2=21.7336, center=true);
translate([575.3302,-182.2884,5.996])
rotate([-18.4825,90,0])
cylinder(300, d1=22.3832, d2=25.585, center=true);
translate([963.5382,660.7674,7.0221])
rotate([16.4966,90,0])
cylinder(300, d1=26.6845, d2=29.4922, center=true);
translate([971.3207,795.1758,7.2948])
rotate([8.0165,90,0])
cylinder(300, d1=26.7929, d2=31.5654, center=true);
translate([883.0641,953.4503,6.9236])
rotate([-66.3061,90,0])
cylinder(300, d1=26.7929, d2=28.5961, center=true);
translate([853.6683,1119.246,6.7304])
rotate([17.5964,90,0])
cylinder(188.1504, d1=25.247, d2=28.5961, center=true);
translate([1040.273,389.5038,7.5674])
rotate([-7.379,90,0])
cylinder(300, d1=27.7916, d2=32.7477, center=true);
translate([1001.1797,166.4872,7.0484])
rotate([40.0074,90,0])
cylinder(251.2786, d1=27.217, d2=29.1703, center=true);
translate([340.746,-1759.7956,5.3212])
rotate([-1.5721,90,0])
cylinder(294.914, d1=20.836, d2=21.7336, center=true);
translate([490.6896,-1755.6804,5.5706])
rotate([-1.5721,90,0])
cylinder(5.086, d1=21.7336, d2=22.831, center=true);
translate([1111.3105,5.3894,7.4841])
rotate([-20.8136,90,0])
cylinder(103.549, d1=28.8921, d2=30.9805, center=true);
translate([991.1851,-819.8551,7.3461])
rotate([2.6509,90,0])
cylinder(300, d1=27.0736, d2=31.6955, center=true);
translate([832.9663,-1252.1918,6.624])
rotate([-26.8985,90,0])
cylinder(300, d1=24.9956, d2=27.9968, center=true);
translate([843.2526,-1535.5048,6.7015])
rotate([-17.5784,90,0])
cylinder(300, d1=25.1197, d2=28.4926, center=true);
translate([500.697,-2297.8535,5.7949])
rotate([10.9153,90,0])
cylinder(300, d1=21.8246, d2=24.5349, center=true);
translate([503.4105,-2269.7399,5.7944])
rotate([0.11081,90,0])
cylinder(300, d1=21.8246, d2=24.5304, center=true);
translate([627.0576,-1667.5625,6.0517])
rotate([-33.3421,90,0])
cylinder(320.3865, d1=22.831, d2=25.5825, center=true);
translate([880.7351,-68.5301,6.6968])
rotate([-22.0883,90,0])
cylinder(352.1277, d1=25.585, d2=27.9894, center=true);
translate([1148.1972,513.4712,7.78])
rotate([68.6944,90,0])
cylinder(224.7664, d1=29.4922, d2=32.7477, center=true);
translate([1267.4,747.2303,8.6417])
rotate([10.3801,90,0])
cylinder(300, d1=31.5654, d2=37.5681, center=true);
translate([1092.6566,1105.126,7.6628])
rotate([-5.4782,90,0])
cylinder(300, d1=28.5961, d2=32.7066, center=true);
translate([1075.3387,1162.0577,7.7301])
rotate([-28.36,90,0])
cylinder(300, d1=28.5961, d2=33.245, center=true);
translate([1330.6074,359.21,8.8027])
rotate([19.2925,90,0])
cylinder(300, d1=32.7477, d2=37.6738, center=true);
translate([1128.5604,54.7508,7.5188])
rotate([44.8326,90,0])
cylinder(87.8377, d1=29.1703, d2=30.9805, center=true);
translate([1234.9358,-51.0049,8.2138])
rotate([44.8326,90,0])
cylinder(212.1623, d1=30.9805, d2=34.7301, center=true);
translate([730.5703,-1580.1604,6.3378])
rotate([-1.2208,90,0])
cylinder(60.6406, d1=25.1197, d2=25.5825, center=true);
translate([880.5362,-1576.9647,6.8534])
rotate([-1.2208,90,0])
cylinder(239.3594, d1=25.5825, d2=29.2443, center=true);
translate([922.5856,65.7419,6.8098])
rotate([29.3002,90,0])
cylinder(278.1693, d1=26.4892, d2=27.9894, center=true);
translate([1053.3958,-7.6658,7.1102])
rotate([29.3002,90,0])
cylinder(21.8307, d1=27.9894, d2=28.8921, center=true);
translate([1430.3299,-215.5762,9.0717])
rotate([36.765,90,0])
cylinder(300, d1=34.7301, d2=37.8432, center=true);
translate([1429.1469,-217.1382,9.0052])
rotate([37.5134,90,0])
cylinder(300, d1=34.7301, d2=37.3111, center=true);
translate([1274.5105,-758.3711,8.3304])
rotate([-27.1386,90,0])
cylinder(300, d1=31.6955, d2=34.9474, center=true);
translate([1053.8811,-1005.5613,7.4615])
rotate([-64.0124,90,0])
cylinder(397.7547, d1=27.9968, d2=31.6955, center=true);
translate([1086.0599,-1448.0535,7.3665])
rotate([-22.894,90,0])
cylinder(216.6929, d1=28.4926, d2=30.4391, center=true);
translate([793.6255,-2290.3642,6.6267])
rotate([-13.8445,90,0])
cylinder(300, d1=24.5349, d2=28.4787, center=true);
translate([790.5224,-2279.5393,6.3728])
rotate([-18.1468,90,0])
cylinder(300, d1=24.5349, d2=26.4474, center=true);
translate([793.236,-2251.4257,6.3722])
rotate([-7.5789,90,0])
cylinder(282.116, d1=24.5304, d2=26.4474, center=true);
translate([1562.0561,749.5013,9.961])
rotate([-11.2633,90,0])
cylinder(300, d1=37.5681, d2=42.1198, center=true);
translate([1328.4583,919.8248,8.7843])
rotate([66.5751,90,0])
cylinder(435.1027, d1=32.7066, d2=37.5681, center=true);
translate([1356.3111,1250.8118,9.121])
rotate([-6.7007,90,0])
cylinder(300, d1=33.245, d2=39.7228, center=true);
translate([1566.7443,193.211,10.1484])
rotate([50.9202,90,0])
cylinder(300, d1=37.6738, d2=43.5135, center=true);
translate([1093.0301,-1490.1593,7.4604])
rotate([-42.2245,90,0])
cylinder(250.7471, d1=29.2443, d2=30.4391, center=true);
translate([1204.1078,-1389.3537,7.8038])
rotate([-42.2245,90,0])
cylinder(49.2529, d1=30.4391, d2=31.9912, center=true);
translate([1550.5887,-310.0283,9.4932])
rotate([32.1783,90,0])
cylinder(5.8133, d1=37.3111, d2=38.6343, center=true);
translate([1290.5216,-1239.1931,8.3493])
rotate([-62.9662,90,0])
cylinder(300, d1=31.9912, d2=34.8034, center=true);
translate([1085.1694,-2219.6469,7.7744])
rotate([-13.4244,90,0])
cylinder(300, d1=28.4787, d2=33.7168, center=true);
translate([946.2958,-2229.3425,6.7721])
rotate([-14.728,90,0])
cylinder(27.3674, d1=26.4474, d2=27.7292, center=true);
translate([1752.7663,635.2752,11.1719])
rotate([73.1024,90,0])
cylinder(300, d1=42.1198, d2=47.2554, center=true);
translate([1655.0755,1260.3624,10.7882])
rotate([3.0389,90,0])
cylinder(300, d1=39.7228, d2=46.5825, center=true);
translate([1748.3488,-45.3902,11.4416])
rotate([54.5287,90,0])
cylinder(300, d1=43.5135, d2=48.0193, center=true);
translate([1807.144,41.6874,11.8358])
rotate([13.5261,90,0])
cylinder(300, d1=43.5135, d2=51.1731, center=true);
translate([1551.7717,-308.4663,9.5597])
rotate([67.6728,90,0])
cylinder(6.724, d1=37.8432, d2=38.6343, center=true);
translate([1608.7561,-447.2207,10.0044])
rotate([67.6728,90,0])
cylinder(293.276, d1=38.6343, d2=41.4011, center=true);
translate([1574.235,-363.1635,9.6252])
rotate([67.6728,90,0])
cylinder(124.9845, d1=37.8432, d2=39.1583, center=true);
translate([1631.2194,-501.9179,10.0699])
rotate([67.6728,90,0])
cylinder(175.0155, d1=39.1583, d2=41.4011, center=true);
translate([949.3989,-2240.1674,7.026])
rotate([-54.691,90,0])
cylinder(35.0562, d1=28.4787, d2=27.7292, center=true);
translate([1036.0968,-2117.7605,7.2489])
rotate([-54.691,90,0])
cylinder(264.9438, d1=27.7292, d2=30.2617, center=true);
translate([1724.0586,-720.5183,10.9376])
rotate([66.5903,90,0])
cylinder(300, d1=41.4011, d2=46.0996, center=true);
translate([1431.1633,-974.2472,8.7984])
rotate([-61.1123,90,0])
cylinder(300, d1=34.8034, d2=35.5838, center=true);
translate([1433.8866,-975.787,8.8522])
rotate([-59.9172,90,0])
cylinder(300, d1=34.8034, d2=36.0144, center=true);
translate([1699.4261,-1535.7025,10.906])
rotate([-46.4523,90,0])
cylinder(300, d1=40.794, d2=46.4542, center=true);
translate([1380.2596,-2169.242,8.9554])
rotate([-5.9621,90,0])
cylinder(300, d1=33.7168, d2=37.9268, center=true);
translate([1378.4343,-2212.8239,8.9503])
rotate([10.7588,90,0])
cylinder(300, d1=33.7168, d2=37.8853, center=true);
translate([1193.8326,-1883.5159,7.7355])
rotate([-57.2397,90,0])
cylinder(300, d1=30.2617, d2=31.6223, center=true);
translate([1193.2468,-1883.1409,7.8291])
rotate([-57.5054,90,0])
cylinder(300, d1=30.2617, d2=32.3709, center=true);
translate([1945.6274,476.8888,12.8977])
rotate([5.6864,90,0])
cylinder(300, d1=47.2554, d2=55.9261, center=true);
translate([1921.462,1158.0437,12.5868])
rotate([38.9845,90,0])
cylinder(300, d1=46.5825, d2=54.112, center=true);
translate([1972.7066,-227.9251,12.8174])
rotate([23.7341,90,0])
cylinder(300, d1=48.0193, d2=54.5196, center=true);
translate([2080.768,-71.9524,13.8991])
rotate([31.5815,90,0])
cylinder(300, d1=51.1731, d2=60.0201, center=true);
translate([1471.1957,-744.6499,9.0229])
rotate([-108.2657,90,0])
cylinder(206.9518, d1=35.5838, d2=36.5992, center=true);
translate([1491.382,-721.465,9.1247])
rotate([-98.0862,90,0])
cylinder(251.5544, d1=36.0144, d2=36.9832, center=true);
translate([1916.8173,-1329.5493,12.0066])
rotate([-40.5079,90,0])
cylinder(300, d1=46.4542, d2=49.5984, center=true);
translate([1554.9694,-2005.8484,9.85])
rotate([-80.204,90,0])
cylinder(300, d1=37.9268, d2=40.8736, center=true);
translate([1576.0932,-2180.9725,9.8986])
rotate([-49.9588,90,0])
cylinder(156.3585, d1=37.8853, d2=41.3035, center=true);
translate([1270.5148,-1680.8053,7.9324])
rotate([-93.3534,90,0])
cylinder(153.4013, d1=31.6223, d2=31.8366, center=true);
translate([1310.7939,-1685.2769,8.4963])
rotate([-62.6121,90,0])
cylinder(160.7089, d1=32.3709, d2=35.5992, center=true);
translate([2233.7713,405.3537,15.2165])
rotate([22.1986,90,0])
cylinder(300, d1=55.9261, d2=65.8057, center=true);
translate([2176.6451,1006.2839,14.6862])
rotate([22.4962,90,0])
cylinder(300, d1=54.112, d2=63.3776, center=true);
translate([2189.6083,-415.4436,14.5813])
rotate([57.9548,90,0])
cylinder(300, d1=54.5196, d2=62.131, center=true);
translate([2357.6141,-167.2607,16.2482])
rotate([6.4121,90,0])
cylinder(300, d1=60.0201, d2=69.9656, center=true);
translate([1423.3801,-668.1686,8.9433])
rotate([-54.7665,90,0])
cylinder(53.3316, d1=34.9474, d2=36.5992, center=true);
translate([1518.3697,-533.6792,9.4697])
rotate([-54.7665,90,0])
cylinder(275.9732, d1=36.5992, d2=39.1583, center=true);
translate([1440.8431,-643.4439,8.9913])
rotate([-54.7665,90,0])
cylinder(113.8715, d1=34.9474, d2=36.9832, center=true);
translate([1535.8327,-508.9545,9.5177])
rotate([-54.7665,90,0])
cylinder(215.4334, d1=36.9832, d2=39.1583, center=true);
translate([1577.9185,-2137.3906,9.9038])
rotate([-18.5561,90,0])
cylinder(102.2566, d1=37.9268, d2=41.3035, center=true);
translate([1720.1204,-2089.6556,11.0922])
rotate([-18.5561,90,0])
cylinder(197.7434, d1=41.3035, d2=47.434, center=true);
translate([1133.1085,-1589.3255,7.6351])
rotate([6.4005,90,0])
cylinder(267.5069, d1=29.2443, d2=31.8366, center=true);
translate([1282.1736,-1606.0471,8.055])
rotate([6.4005,90,0])
cylinder(32.4931, d1=31.8366, d2=32.6031, center=true);
translate([1323.0384,-1610.8937,8.5253])
rotate([7.0007,90,0])
cylinder(49.8104, d1=32.6031, d2=35.5992, center=true);
translate([1471.9201,-1629.1759,9.5491])
rotate([7.0007,90,0])
cylinder(250.1896, d1=35.5992, d2=40.794, center=true);
translate([2214.392,-948.9959,14.9846])
rotate([-5.1051,90,0])
cylinder(300, d1=55.3054, d2=64.5714, center=true);
translate([2171.6175,-1207.0348,14.239])
rotate([-55.6371,90,0])
cylinder(300, d1=56.021, d2=57.8907, center=true);
translate([2236.7205,-1322.5141,15.2253])
rotate([-3.1883,90,0])
cylinder(300, d1=56.021, d2=65.7815, center=true);
translate([2027.5338,-1089.679,12.4621])
rotate([-91.3396,90,0])
cylinder(284.9524, d1=49.5984, d2=50.0987, center=true);
translate([1702.6767,-1771.0267,10.6589])
rotate([-35.4547,90,0])
cylinder(300, d1=40.8736, d2=44.3975, center=true);
translate([1932.7802,-1966.7797,12.6126])
rotate([-37.5469,90,0])
cylinder(300, d1=47.434, d2=53.4665, center=true);
translate([1951.9926,-1999.7347,12.884])
rotate([-22.9365,90,0])
cylinder(300, d1=47.434, d2=55.6379, center=true);
translate([2487.176,251.8073,17.5303])
rotate([40.2276,90,0])
cylinder(300, d1=65.8057, d2=74.4365, center=true);
translate([2522.2818,338.1309,17.7051])
rotate([4.0332,90,0])
cylinder(300, d1=65.8057, d2=75.8354, center=true);
translate([2454.5185,893.2224,16.912])
rotate([21.7848,90,0])
cylinder(300, d1=63.3776, d2=71.9187, center=true);
translate([2418.9932,-550.3959,16.8709])
rotate([2.9837,90,0])
cylinder(300, d1=62.131, d2=72.836, center=true);
translate([2634.3241,-262.79,18.8773])
rotate([31.6806,90,0])
cylinder(300, d1=69.9656, d2=81.053, center=true);
translate([1903.9285,-902.7066,12.0248])
rotate([20.3186,90,0])
cylinder(256.5098, d1=46.0996, d2=50.0987, center=true);
translate([2044.595,-954.7925,13.1755])
rotate([20.3186,90,0])
cylinder(43.4902, d1=50.0987, d2=55.3054, center=true);
translate([2510.85,-993.1552,17.5955])
rotate([13.4426,90,0])
cylinder(300, d1=65.3914, d2=75.3728, center=true);
translate([2488.0661,-851.6415,17.2825])
rotate([-34.059,90,0])
cylinder(300, d1=64.5714, d2=73.6887, center=true);
translate([2294.0349,-1020.973,14.6997])
rotate([-58.7604,90,0])
cylinder(145.5891, d1=57.8907, d2=59.707, center=true);
translate([2521.6144,-1171.0987,17.6443])
rotate([-46.6362,90,0])
cylinder(393.5931, d1=65.7815, d2=75.3728, center=true);
translate([1840.7999,-1546.3729,11.549])
rotate([-83.3955,90,0])
cylinder(277.129, d1=44.3975, d2=47.9948, center=true);
translate([2155.9501,-1767.5086,14.0414])
rotate([-45.9773,90,0])
cylinder(300, d1=53.4665, d2=58.8649, center=true);
translate([2218.3104,-1863.3641,14.766])
rotate([-31.2938,90,0])
cylinder(300, d1=55.6379, d2=62.4904, center=true);
translate([2224.7944,-1875.1998,14.7944])
rotate([-26.1372,90,0])
cylinder(300, d1=55.6379, d2=62.7175, center=true);
translate([2749.6584,130.2767,20.1424])
rotate([9.4611,90,0])
cylinder(300, d1=74.4365, d2=86.7031, center=true);
translate([2738.2069,92.76,19.9066])
rotate([24.4872,90,0])
cylinder(300, d1=74.4365, d2=84.8164, center=true);
translate([2784.7642,216.6004,20.3173])
rotate([44.5204,90,0])
cylinder(316.5605, d1=75.8354, d2=86.7031, center=true);
translate([2685.3173,718.7025,18.9635])
rotate([52.4051,90,0])
cylinder(300, d1=71.9187, d2=79.789, center=true);
translate([2708.9357,-611.6748,19.4661])
rotate([20.8838,90,0])
cylinder(300, d1=72.836, d2=82.893, center=true);
translate([2911.9719,-341.9676,21.6586])
rotate([0.15284,90,0])
cylinder(300, d1=81.053, d2=92.2162, center=true);
translate([2198.3872,-960.5382,14.3766])
rotate([-0.77522,90,0])
cylinder(266.8248, d1=55.3054, d2=59.707, center=true);
translate([2348.3735,-958.5088,15.6373])
rotate([-0.77522,90,0])
cylinder(33.1752, d1=59.707, d2=65.3914, center=true);
translate([1829.7534,-1417.8551,11.8061])
rotate([-18.6883,90,0])
cylinder(56.9707, d1=46.4542, d2=47.9948, center=true);
translate([1971.8448,-1369.7923,13.002])
rotate([-18.6883,90,0])
cylinder(243.0293, d1=47.9948, d2=56.021, center=true);
translate([2730.7084,-716.3902,19.5727])
rotate([-23.4081,90,0])
cylinder(257.978, d1=73.6887, d2=82.893, center=true);
translate([2323.34,-1486.9102,15.5808])
rotate([-69.919,90,0])
cylinder(367.839, d1=58.8649, d2=65.7815, center=true);
translate([2435.7736,-1679.5837,16.0351])
rotate([-59.4953,90,0])
cylinder(300.6956, d1=62.7175, d2=65.5632, center=true);
translate([3043.7345,139.5314,22.5306])
rotate([-13.0662,90,0])
cylinder(300, d1=86.7031, d2=93.5419, center=true);
translate([3000.3798,-51.318,22.3126])
rotate([33.0951,90,0])
cylinder(300, d1=84.8164, d2=93.6846, center=true);
translate([2881.6722,492.5765,21.0908])
rotate([45.6565,90,0])
cylinder(300, d1=79.789, d2=88.9374, center=true);
translate([2955.5264,-503.7568,21.8886])
rotate([-56.593,90,0])
cylinder(386.6624, d1=82.893, d2=92.2162, center=true);
translate([2429.2896,-1667.748,16.0067])
rotate([-54.8741,90,0])
cylinder(287.819, d1=62.4904, d2=65.5632, center=true);
translate([2515.5958,-1545.0645,16.7435])
rotate([-54.8741,90,0])
cylinder(12.181, d1=65.5632, d2=68.3846, center=true);
translate([2592.3123,-1409.1635,18.0044])
rotate([-60.7854,90,0])
cylinder(300, d1=68.3846, d2=75.6506, center=true);
translate([3199.0588,-162.5189,23.9461])
rotate([21.8627,90,0])
cylinder(157.3446, d1=93.6846, d2=97.8838, center=true);
translate([3094.2921,276.6745,23.6162])
rotate([45.2254,90,0])
cylinder(306.0435, d1=88.9374, d2=99.9923, center=true);
translate([3447.5351,-118.4446,27.8526])
rotate([-19.1405,90,0])
cylinder(300, d1=105.5756, d2=117.2453, center=true);
translate([3167.0221,-267.0915,23.7625])
rotate([-35.6243,90,0])
cylinder(258.4739, d1=92.2162, d2=97.8838, center=true);
translate([3288.9502,-179.7213,25.4324])
rotate([-35.6243,90,0])
cylinder(41.5261, d1=97.8838, d2=105.5756, center=true);
translate([3195.9596,170.7449,24.1918])
rotate([23.8291,90,0])
cylinder(13.3559, d1=93.5419, d2=99.9923, center=true);
translate([3333.1728,110.1435,26.7449])
rotate([23.8291,90,0])
cylinder(286.6441, d1=99.9923, d2=113.9667, center=true);
translate([3243.8484,-579.8806,25.2533])
rotate([-54.5264,90,0])
cylinder(300, d1=95.7624, d2=106.2639, center=true);
translate([2770.3967,-1170.9971,19.4341])
rotate([-45.6414,90,0])
cylinder(300, d1=75.6506, d2=79.8221, center=true);
translate([2780.1528,-1181.4948,19.7423])
rotate([-40.1652,90,0])
cylinder(300, d1=75.6506, d2=82.2876, center=true);
translate([3612.6074,29.9198,30.5115])
rotate([8.5575,90,0])
cylinder(300, d1=113.9667, d2=130.1255, center=true);
translate([3675.0901,-30.8311,30.9213])
rotate([-24.1162,90,0])
cylinder(188.1136, d1=117.2453, d2=130.1255, center=true);
translate([3461.3715,-383.7193,27.9473])
rotate([-29.5616,90,0])
cylinder(300, d1=106.2639, d2=117.3141, center=true);
translate([2882.4682,-985.7693,20.0807])
rotate([-84.7252,90,0])
cylinder(156.6255, d1=79.8221, d2=80.8235, center=true);
translate([2941.2665,-961.5882,21.2809])
rotate([-69.3212,90,0])
cylinder(263.2769, d1=82.2876, d2=87.9599, center=true);
translate([3910.9094,4.6963,34.7049])
rotate([1.109,90,0])
cylinder(300, d1=130.1255, d2=147.5139, center=true);
translate([2773.2041,-967.9071,19.5245])
rotate([-27.3029,90,0])
cylinder(262.1301, d1=75.3728, d2=80.8235, center=true);
translate([2906.4931,-899.1028,20.4646])
rotate([-27.3029,90,0])
cylinder(37.8699, d1=80.8235, d2=82.8934, center=true);
translate([2955.5353,-864.4241,21.3567])
rotate([-38.8977,90,0])
cylinder(82.7906, d1=82.8934, d2=87.9599, center=true);
translate([3072.2756,-770.2344,22.9653])
rotate([-38.8977,90,0])
cylinder(217.2094, d1=87.9599, d2=95.7624, center=true);
translate([3676.3914,-151.058,30.93])
rotate([-61.9475,90,0])
cylinder(359.5565, d1=117.3141, d2=130.1255, center=true);
translate([4208.3565,29.1989,39.211])
rotate([-10.5274,90,0])
cylinder(300, d1=147.5139, d2=166.1739, center=true);
translate([4505.6968,62.9639,44.2485])
rotate([-2.4298,90,0])
cylinder(300, d1=166.1739, d2=187.8138, center=true);
translate([4505.766,52.1695,44.2491])
rotate([1.6944,90,0])
cylinder(300, d1=166.1739, d2=187.8186, center=true);
translate([4827.781,34.6615,46.954])
rotate([11.3796,90,0])
cylinder(351.345, d1=187.8138, d2=187.8186, center=true);
translate([4827.8502,23.8671,46.9546])
rotate([7.8933,90,0])
cylinder(347.5928, d1=187.8186, d2=187.8186, center=true);
translate([-5000,0,50])
sphere(d=200);
translate([-4400,0,50])
sphere(d=200);
translate([-4100.0012,0,35.258])
sphere(d=141.0321);
translate([-3805.6008,57.6924,33.1243])
sphere(d=132.4974);
translate([-3510.9265,1.4161,29.0892])
sphere(d=116.3568);
translate([-3514.7879,131.3665,29.1146])
sphere(d=116.4586);
translate([-3210.9289,0.20382,25.3325])
sphere(d=101.33);
translate([-3212.3944,-28.2254,25.3414])
sphere(d=101.3655);
translate([-3221.789,195.7994,25.4217])
sphere(d=101.6866);
translate([-2917.0372,-60.0261,20.5462])
sphere(d=82.1846);
translate([-2960.6325,-51.0917,22.1478])
sphere(d=88.5913);
translate([-2923.3048,225.9189,21.993])
sphere(d=87.9719);
translate([-2639.6117,-174.1974,18.8944])
sphere(d=75.5774);
translate([-2635.8562,311.7868,18.9069])
sphere(d=75.6277);
translate([-2359.8903,-282.6224,16.2478])
sphere(d=64.991);
translate([-2360.0758,429.8766,16.2317])
sphere(d=64.9268);
translate([-2365.7776,181.1821,16.2574])
sphere(d=65.0294);
translate([-2061.4842,-313.5058,13.7968])
sphere(d=55.1874);
translate([-2274.2404,-570.136,14.6638])
sphere(d=58.6553);
translate([-2067.1039,494.4327,13.82])
sphere(d=55.2799);
translate([-2066.59,159.119,13.8406])
sphere(d=55.3626);
translate([-1789.2814,-439.6233,11.6728])
sphere(d=46.6911);
translate([-1879.8687,-74.726,11.9904])
sphere(d=47.9617);
translate([-2047.0897,-766.1017,13.4033])
sphere(d=53.613);
translate([-2005.7921,-704.0596,13.2434])
sphere(d=52.9736);
translate([-1774.992,562.7747,11.6428])
sphere(d=46.5711);
translate([-1790.1931,609.8467,11.6954])
sphere(d=46.7817);
translate([-1769.2768,119.0589,11.6212])
sphere(d=46.485);
translate([-1492.368,-396.6995,9.8462])
sphere(d=39.3846);
translate([-1607.2221,50.4293,10.4719])
sphere(d=41.8876);
translate([-1785.0579,-912.1816,11.6084])
sphere(d=46.4336);
translate([-1482.6357,630.0636,8.9679])
sphere(d=35.8717);
translate([-1486.8119,629.1025,9.8324])
sphere(d=39.3298);
translate([-1469.9499,139.1439,9.7217])
sphere(d=38.8867);
translate([-1196.5753,-346.6327,8.2537])
sphere(d=33.0147);
translate([-1492.3812,-978.0629,9.8337])
sphere(d=39.3349);
translate([-1205.6802,745.3703,8.2522])
sphere(d=33.0087);
translate([-1173.1176,182.6254,8.1436])
sphere(d=32.5745);
translate([-1174.2127,189.5376,8.1462])
sphere(d=32.5849);
translate([-898.9099,-383.9866,6.976])
sphere(d=27.9039);
translate([-917.4238,-236.749,7.011])
sphere(d=28.0442);
translate([-1211.4437,-1083.2966,8.2898])
sphere(d=33.1592);
translate([-1222.5867,-846.8724,8.317])
sphere(d=33.2679);
translate([-939.9148,884.542,7.0716])
sphere(d=28.2864);
translate([-906.1095,761.4144,7.0068])
sphere(d=28.0274);
translate([-877.8176,235.5203,6.8929])
sphere(d=27.5714);
translate([-939.3178,376.1505,7.0102])
sphere(d=28.0406);
translate([-886.3293,273.9363,6.9106])
sphere(d=27.6425);
translate([-611.0057,-299.6589,6.0512])
sphere(d=24.205);
translate([-911.4535,-1080.8689,7.028])
sphere(d=28.112);
translate([-926.3515,-799.4938,7.0781])
sphere(d=28.3123);
translate([-639.9346,881.0969,6.1232])
sphere(d=24.4927);
translate([-580.2062,197.7384,5.9678])
sphere(d=23.8713);
translate([-663.0819,493.1709,6.1555])
sphere(d=24.6218);
translate([-362.1662,-132.0913,5.2471])
sphere(d=20.9884);
translate([-611.5572,-1088.7561,6.0438])
sphere(d=24.1752);
translate([-719.6973,-1311.5842,6.1973])
sphere(d=24.7892);
translate([-694.3693,-609.2723,6.182])
sphere(d=24.7281);
translate([-727.805,-574.5954,6.2313])
sphere(d=24.9252);
translate([-360.4597,772.0382,5.4504])
sphere(d=21.8014);
translate([-394.5101,1053.6275,5.4815])
sphere(d=21.9261);
translate([-280.9853,219.3454,5.3337])
sphere(d=21.335);
translate([-455.7792,-75.2414,5.483])
sphere(d=21.9319);
translate([-383.0288,600.736,5.4925])
sphere(d=21.9698);
translate([-63.902,-99.8662,5.0817])
sphere(d=20.3268);
translate([-316.3428,-1035.3853,5.3874])
sphere(d=21.5498);
translate([-423.8855,-1261.6306,5.5885])
sphere(d=22.354);
translate([-620.1476,-1594.5857,5.8078])
sphere(d=23.2313);
translate([-403.7589,-534.8035,5.3124])
sphere(d=21.2494);
translate([-429.376,-541.3679,5.6026])
sphere(d=22.4103);
translate([-62.8541,809.8657,5.0806])
sphere(d=20.3226);
translate([-151.9246,556.3692,5.0607])
sphere(d=20.2427);
translate([-96.1654,1085.099,5.1083])
sphere(d=20.4334);
translate([17.5607,189.8452,5.0472])
sphere(d=20.189);
translate([-38.2308,43.0779,5.0459])
sphere(d=20.1834);
translate([-378.841,-143.3201,5.4409])
sphere(d=21.7636);
translate([-215.2603,621.8716,5.1611])
sphere(d=20.6443);
translate([213.8009,13.6289,5.2355])
sphere(d=20.9419);
translate([-16.6569,-1049.1097,5.0499])
sphere(d=20.1996);
translate([-171.683,-1424.0926,5.1596])
sphere(d=20.6385);
translate([-405.2239,-1803.8889,5.4731])
sphere(d=21.8925);
translate([-107.1533,-489.8018,5.1175])
sphere(d=20.4699);
translate([228.2507,737.3541,5.2565])
sphere(d=21.0259);
translate([191.0232,969.6979,5.2016])
sphere(d=20.8062);
translate([84.7679,372.0417,5.0256])
sphere(d=20.1023);
translate([49.2451,333.8142,5.0115])
sphere(d=20.0461);
translate([198.159,1143.1777,5.2059])
sphere(d=20.8235);
translate([306.4759,270.6413,5.375])
sphere(d=21.5001);
translate([236.6422,394.7922,5.3198])
sphere(d=21.2793);
translate([137.1418,-17.7011,5.0554])
sphere(d=20.2217);
translate([509.5727,63.8186,5.7733])
sphere(d=23.0931);
translate([250.676,-912.9734,5.2876])
sphere(d=21.1504);
translate([128.0181,-1410.7046,5.1382])
sphere(d=20.5527);
translate([52.3769,-1623.5849,5.0944])
sphere(d=20.3775);
translate([-181.276,-2003.5069,5.1548])
sphere(d=20.6192);
translate([-106.293,-1778.5836,5.1177])
sphere(d=20.471);
translate([157.7263,-348.9516,5.1571])
sphere(d=20.6283);
translate([159.2784,-351.9102,5.1579])
sphere(d=20.6316);
translate([526.706,767.7591,5.8195])
sphere(d=23.278);
translate([478.2291,1056.374,5.6944])
sphere(d=22.7776);
translate([153.6867,317.1887,5.0686])
sphere(d=20.2742);
translate([110.8069,277.0754,5.0543])
sphere(d=20.2173);
translate([606.411,276.882,6.0239])
sphere(d=24.0957);
translate([599.4868,206.263,6.0146])
sphere(d=24.0582);
translate([801.2944,133.8078,6.6223])
sphere(d=26.4892);
translate([548.7782,-879.2821,5.8696])
sphere(d=23.4784);
translate([426.1315,-1444.2966,5.5699])
sphere(d=22.2794);
translate([405.5797,-1524.5446,5.5503])
sphere(d=22.2012);
translate([73.1135,-2162.5225,5.0819])
sphere(d=20.3275);
translate([193.3445,-1763.8411,5.209])
sphere(d=20.836);
translate([190.9426,-1737.9511,5.2075])
sphere(d=20.8301);
translate([433.0671,-229.8406,5.5958])
sphere(d=22.3832);
translate([819.7127,703.3613,6.6711])
sphere(d=26.6845);
translate([822.7865,816.0945,6.6982])
sphere(d=26.7929);
translate([763.995,1147.6859,6.3117])
sphere(d=25.247);
translate([891.5153,370.239,6.9479])
sphere(d=27.7916);
translate([904.9449,247.2591,6.8042])
sphere(d=27.217);
translate([902.0345,247.5479,6.4693])
sphere(d=25.8773);
translate([1097.4145,85.7153,7.2926])
sphere(d=29.1703);
translate([1062.9147,-13.0077,7.223])
sphere(d=28.8921);
translate([841.3457,-812.9174,6.7684])
sphere(d=27.0736);
translate([699.195,-1320.0536,6.2489])
sphere(d=24.9956);
translate([700.2569,-1580.8063,6.2799])
sphere(d=25.1197);
translate([353.4108,-2269.4498,5.4562])
sphere(d=21.8246);
translate([493.2316,-1755.6106,5.7078])
sphere(d=22.831);
translate([488.1475,-1755.7501,5.4334])
sphere(d=21.7336);
translate([717.5933,-134.7363,6.3962])
sphere(d=25.585);
translate([1107.3636,618.1736,7.373])
sphere(d=29.4922);
translate([1119.8549,774.257,7.8913])
sphere(d=31.5654);
translate([943.3417,1090.8061,7.149])
sphere(d=28.5961);
translate([1189.0308,408.7687,8.1869])
sphere(d=32.7477);
translate([1310.1653,-125.7961,8.6825])
sphere(d=34.7301);
translate([1159.7063,23.7864,7.7451])
sphere(d=30.9805);
translate([1141.0246,-826.7927,7.9239])
sphere(d=31.6955);
translate([966.7377,-1184.33,6.9992])
sphere(d=27.9968);
translate([1000.1888,-1574.4149,7.3111])
sphere(d=29.2443);
translate([986.2483,-1490.2033,7.1231])
sphere(d=28.4926);
translate([647.9832,-2326.2573,6.1337])
sphere(d=24.5349);
translate([653.4102,-2270.03,6.1326])
sphere(d=24.5304);
translate([760.8837,-1579.5144,6.3956])
sphere(d=25.5825);
translate([1043.8769,-2.324,6.9974])
sphere(d=27.9894);
translate([1414.9451,720.2036,9.392])
sphere(d=37.5681);
translate([1241.9715,1119.446,8.1766])
sphere(d=32.7066);
translate([1207.3357,1233.3093,8.3112])
sphere(d=33.245);
translate([1472.184,309.6514,9.4184])
sphere(d=37.6738);
translate([1550.4945,-305.3563,9.4608])
sphere(d=37.8432);
translate([1548.1285,-308.4803,9.3278])
sphere(d=37.3111);
translate([1407.9964,-689.9494,8.7369])
sphere(d=34.9474);
translate([1222.3441,-1372.8039,7.9978])
sphere(d=31.9912);
translate([1298.3189,-1607.8583,8.1508])
sphere(d=32.6031);
translate([1185.8714,-1405.9036,7.6098])
sphere(d=30.4391);
translate([939.2679,-2254.4712,7.1197])
sphere(d=28.4787);
translate([933.0617,-2232.8214,6.6119])
sphere(d=26.4474);
translate([1709.1671,778.7991,10.5299])
sphere(d=42.1198);
translate([1505.2865,1268.3144,9.9307])
sphere(d=39.7228);
translate([1661.3045,76.7706,10.8784])
sphere(d=43.5135);
translate([1664.4632,-582.8651,10.3503])
sphere(d=41.4011);
translate([1553.0489,-311.5762,9.6586])
sphere(d=38.6343);
translate([1597.9756,-420.9707,9.7896])
sphere(d=39.1583);
translate([1358.699,-1105.5823,8.7009])
sphere(d=34.8034);
translate([1596.0823,-1644.4226,10.1985])
sphere(d=40.794);
translate([1231.071,-2184.8226,8.4292])
sphere(d=33.7168);
translate([1112.6637,-2009.6572,7.5654])
sphere(d=30.2617);
translate([959.5299,-2225.8637,6.9323])
sphere(d=27.7292);
translate([1796.3655,491.7513,11.8138])
sphere(d=47.2554);
translate([1804.8646,1252.4103,11.6456])
sphere(d=46.5825);
translate([1835.3932,-167.5511,12.0048])
sphere(d=48.0193);
translate([1952.9835,6.6042,12.7933])
sphere(d=51.1731);
translate([1783.6541,-858.1714,11.5249])
sphere(d=46.0996);
translate([1503.6275,-842.912,8.896])
sphere(d=35.5838);
translate([1509.0741,-845.9917,9.0036])
sphere(d=36.0144);
translate([1802.7699,-1426.9824,11.6135])
sphere(d=46.4542);
translate([1529.4483,-2153.6614,9.4817])
sphere(d=37.9268);
translate([1525.7975,-2240.8252,9.4713])
sphere(d=37.8853);
translate([1275.0014,-1757.3747,7.9056])
sphere(d=31.6223);
translate([1273.8299,-1756.6247,8.0927])
sphere(d=32.3709);
translate([2094.8893,462.0264,13.9815])
sphere(d=55.9261);
translate([2038.0593,1063.6771,13.528])
sphere(d=54.112);
translate([2110.0201,-288.2991,13.6299])
sphere(d=54.5196);
translate([2208.5524,-150.509,15.005])
sphere(d=60.0201);
translate([2064.987,-962.3433,13.8264])
sphere(d=55.3054);
translate([1438.7639,-646.3878,9.1498])
sphere(d=36.5992);
translate([1473.6899,-596.9383,9.2458])
sphere(d=36.9832);
translate([2086.9527,-1330.8567,14.0053])
sphere(d=56.021);
translate([2030.8647,-1232.1163,12.3996])
sphere(d=49.5984);
translate([1580.4906,-1858.0355,10.2184])
sphere(d=40.8736);
translate([1813.8519,-2058.1913,11.8585])
sphere(d=47.434);
translate([1626.3888,-2121.1199,10.3259])
sphere(d=41.3035);
translate([1266.0283,-1604.236,7.9591])
sphere(d=31.8366);
translate([1347.7579,-1613.9292,8.8998])
sphere(d=35.5992);
translate([2372.6532,348.6811,16.4514])
sphere(d=65.8057);
translate([2315.2309,948.8907,15.8444])
sphere(d=63.3776);
translate([2269.1965,-542.588,15.5328])
sphere(d=62.131);
translate([2506.6757,-184.0124,17.4914])
sphere(d=69.9656);
translate([2364.9595,-958.2844,16.3479])
sphere(d=65.3914);
translate([2363.7969,-935.6485,16.1429])
sphere(d=64.5714);
translate([2256.2823,-1083.2129,14.4727])
sphere(d=57.8907);
translate([2386.4883,-1314.1715,16.4454])
sphere(d=65.7815);
translate([2024.2029,-947.2418,12.5247])
sphere(d=50.0987);
translate([1824.8629,-1684.0178,11.0994])
sphere(d=44.3975);
translate([2051.7085,-1875.3682,13.3666])
sphere(d=53.4665);
translate([2090.1332,-1941.2781,13.9095])
sphere(d=55.6379);
translate([2601.6988,154.9335,18.6091])
sphere(d=74.4365);
translate([2671.9103,327.5807,18.9588])
sphere(d=75.8354);
translate([2593.8061,837.5541,17.9797])
sphere(d=71.9187);
translate([2568.7899,-558.2037,18.209])
sphere(d=72.836);
translate([2761.9724,-341.5675,20.2632])
sphere(d=81.053);
translate([2656.7405,-1028.0259,18.8432])
sphere(d=75.3728);
translate([2612.3353,-767.6345,18.4222])
sphere(d=73.6887);
translate([2331.7874,-958.7332,14.9267])
sphere(d=59.707);
translate([1856.7369,-1408.7279,11.9987])
sphere(d=47.9948);
translate([2260.1916,-1659.649,14.7162])
sphere(d=58.8649);
translate([2346.4877,-1785.4502,15.6226])
sphere(d=62.4904);
translate([2359.4557,-1809.1216,15.6794])
sphere(d=62.7175);
translate([2897.618,105.62,21.6758])
sphere(d=86.7031);
translate([2874.715,30.5865,21.2041])
sphere(d=84.8164);
translate([2776.8285,599.8509,19.9473])
sphere(d=79.789);
translate([2849.0815,-665.1458,20.7232])
sphere(d=82.893);
translate([3061.9714,-342.3678,23.0541])
sphere(d=92.2162);
translate([2923.3186,-890.4175,20.7233])
sphere(d=82.8934);
translate([2519.1001,-1540.0832,17.0961])
sphere(d=68.3846);
translate([2512.0915,-1550.0459,16.3908])
sphere(d=65.5632);
translate([3189.8509,173.4429,23.3855])
sphere(d=93.5419);
translate([3126.0446,-133.2226,23.4212])
sphere(d=93.6846);
translate([2986.5159,385.3021,22.2344])
sphere(d=88.9374);
translate([3305.8276,-167.6275,26.3939])
sphere(d=105.5756);
translate([3156.7992,-702.0381,23.9406])
sphere(d=95.7624);
translate([2665.5246,-1278.2438,18.9126])
sphere(d=75.6506);
translate([3464.2774,52.2401,28.4917])
sphere(d=113.9667);
translate([3272.0729,-191.8151,24.4709])
sphere(d=97.8838);
translate([3202.0683,168.047,24.9981])
sphere(d=99.9923);
translate([3589.2427,-69.2616,29.3113])
sphere(d=117.2453);
translate([3330.8977,-457.7232,26.566])
sphere(d=106.2639);
translate([2875.2688,-1063.7505,19.9555])
sphere(d=79.8221);
translate([2894.7811,-1084.7458,20.5719])
sphere(d=82.2876);
translate([3760.9375,7.5995,32.5314])
sphere(d=130.1255);
translate([3591.8454,-309.7155,29.3285])
sphere(d=117.3141);
translate([2889.6676,-907.7882,20.2059])
sphere(d=80.8235);
translate([2987.7519,-838.4307,21.99])
sphere(d=87.9599);
translate([4060.8813,1.7932,36.8785])
sphere(d=147.5139);
translate([4355.8316,56.6047,41.5435])
sphere(d=166.1739);
translate([4655.5619,69.323,46.9534])
sphere(d=187.8138);
translate([4655.7005,47.7343,46.9546])
sphere(d=187.8186);
translate([5000,0,46.9546])
sphere(d=187.8186);
translate([-5000,250,50])
rotate([0,90,90])
cylinder(500, d=200, center=true);
translate([5000,250,50])
rotate([0,90,90])
cylinder(500, d=200, center=true);
}
translate([0,0,-100])
cube([25000,100000,200],center=true);
}

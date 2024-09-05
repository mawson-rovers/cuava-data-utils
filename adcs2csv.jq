def cols: [
    "attitude_estimation_mode",
    "control_mode",
    "estimated_x_angular_rate",
    "estimated_y_angular_rate",
    "estimated_z_angular_rate",
    "estimated_roll_angle",
    "estimated_pitch_angle",
    "estimated_yaw_angle"
];

to_entries
    | map(.key as $key | .value as $row | cols | [ $key ] + map($row[.])) as $rows
    | [ "time" ] + cols, $rows[]
    | @csv

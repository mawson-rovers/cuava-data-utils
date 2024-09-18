## CUAVA data utilities

This repository contains scripts and data examples from CUAVA satellites for manipulation.

### Data files

The repository contains two copies of the data:

* `raw/` contains the unprocessed original files from the teleoperation sessions
* `json/` contains data which has been cleaned up and formatted as correct JSON
* `csv/` is an output directory which will be empty until you run `convert.sh`.

### Usage

The `adcs2csv.jq` file contains a filter to be used with the `jq` command line tool to convert
ADCS JSON files into CSV output with selected columns.

```sh
% jq -rf adcs2csv.jq json/20240903-ws1-adcs.json
"time","attitude_estimation_mode","estimated_x_angular_rate","estimated_y_angular_rate","estimated_z_angular_rate"
"2024-09-03T00:07:20Z","MagmeterFineSun",-575,-615,108
"2024-09-03T01:32:20Z","MagmeterFineSun",-620,-533,86
"2024-09-03T01:33:20Z","MagmeterFineSun",-660,-510,124
...
```

Edit the `adcs2csv.jq` file to select the columns you want in the output.

To automatically convert all the files in the `json/` folder, run the provided `convert.sh` script.
All the resulting files will be put in the `csv/` folder, overwriting any files already there.

### Access to CUAVA data bucket

Make a profile to be used to assume the required role to access the bucket in `~/.aws/config`

```ini
[default]
region = ap-southeast-2

[profile fetchbeacon]
role_arn = arn:aws:iam::637423504145:role/cargo-lambda-role-e28d913c-a7fb-4e16-a946-b7bf6a1d7768
source_profile = default
```

Add an accesskey for your AWS account in `~/.aws/credentials`

```ini
[default]
aws_access_key_id = {{ID}}
aws_secret_access_key = {{KEY}}
```

Use the s3 commands with the profile to access the bucket:

```sh
aws s3 ls --profile fetchbeacon s3://cuava-beacons/
aws s3 cp --profile fetchbeacon s3://cuava-beacons/example.json example.json
```

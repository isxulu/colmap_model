#!/bin/sh
seq=$1  # used as ./run.sh 0
PROJECT_PATH=$(dirname "$PWD")
echo $PROJECT_PATH
DATASET_PATH=$PROJECT_PATH/kitti_lead_drop50

mkdir $DATASET_PATH/seq_0${seq}/images
cp -r $DATASET_PATH/seq_0${seq}/image_00 $DATASET_PATH/seq_0${seq}/images/
cp -r $DATASET_PATH/seq_0${seq}/image_01 $DATASET_PATH/seq_0${seq}/images/

mkdir $DATASET_PATH/seq_0${seq}/sparse_model
touch $DATASET_PATH/seq_0${seq}/sparse_model/images.txt
touch $DATASET_PATH/seq_0${seq}/sparse_model/cameras.txt
touch $DATASET_PATH/seq_0${seq}/sparse_model/points3D.txt

echo "1. Extracting features now!"
colmap feature_extractor \
    --database_path $DATASET_PATH/seq_0${seq}/database.db \
    --image_path $DATASET_PATH/seq_0${seq}/images

echo "2. Matching features now!"
colmap exhaustive_matcher --database_path $DATASET_PATH/seq_0${seq}/database.db

echo "** modify sparse_model in sequence of 'images' table in the database"
python ./utils/write_txt.py --path $DATASET_PATH/seq_0${seq}

echo "3. Triangulating points now!"
mkdir $DATASET_PATH/seq_0${seq}/triangulated_model
colmap point_triangulator \
    --database_path $DATASET_PATH/seq_0${seq}/database.db  \
    --image_path $DATASET_PATH/seq_0${seq}/images \
    --input_path $DATASET_PATH/seq_0${seq}/sparse_model \
    --output_path $DATASET_PATH/seq_0${seq}/triangulated_model

echo "4. convert model into ply format!"
mkdir $DATASET_PATH/seq_0${seq}/output_ply
colmap model_converter \
        --input_path $DATASET_PATH/seq_0${seq}/triangulated_model \
        --output_path $DATASET_PATH/seq_0${seq}/output_ply/tri.ply \
        --output_type PLY

echo "5. undistorting images now! "
mkdir $DATASET_PATH/seq_0${seq}/dense_ws
colmap image_undistorter \
    --image_path $DATASET_PATH/seq_0${seq}/images \
    --input_path $DATASET_PATH/seq_0${seq}/triangulated_model \
    --output_path $DATASET_PATH/seq_0${seq}/dense_ws

echo "6. stereo matching now! "
colmap patch_match_stereo \
    --workspace_path $DATASET_PATH/seq_0${seq}/dense_ws

echo "7. fusing stereoes now! "
colmap stereo_fusion \
    --workspace_path $DATASET_PATH/seq_0${seq}/dense_ws \
    --output_path $DATASET_PATH/seq_0${seq}/dense_ws/fused.ply
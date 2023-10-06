seq=4
PROJECT_PATH=$(dirname "$PWD")
echo $PROJECT_PATH
DATASET_PATH=$PROJECT_PATH/kitti_lead_drop50_openmvs

echo "1. Extracting features now!"
colmap feature_extractor \
    --database_path $DATASET_PATH/seq_0${seq}/database.db \
    --image_path $DATASET_PATH/seq_0${seq}/images

echo "2. Matching features now!"
colmap exhaustive_matcher --database_path $DATASET_PATH/seq_0${seq}/database.db

echo "** modify sparse_model in sequence of 'images' table in the database"
# python ./utils/write_cam.py
# python ./utils/write_image.py
python ./write_txt.py

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


# colmap image_undistorter --image_path ./images --input_path ./colmap/sparse/0 --output_path ./colmap/dense --output_type COLMAP
# mkdir $DATASET_PATH/seq_0${seq}/dense_ws/convert2txt

echo "6. convert model to TXT format!"
colmap model_converter \
    --input_path $DATASET_PATH/seq_0${seq}/dense_ws/sparse \
    --output_path $DATASET_PATH/seq_0${seq}/dense_ws/sparse \
    --output_type TXT

echo "7. output MVS file!"
mkdir $DATASET_PATH/seq_0${seq}/mvs
InterfaceCOLMAP \
    --working-folder $DATASET_PATH/seq_0${seq}/dense_ws \
    --input-file $DATASET_PATH/seq_0${seq}/dense_ws \
    --output-file $DATASET_PATH/seq_0${seq}/mvs/model_colmap.mvs

echo "8. Convert MVS file to PLY format!"
DensifyPointCloud \
    --working-folder $DATASET_PATH/seq_0${seq}/dense_ws \
    --input-file $DATASET_PATH/seq_0${seq}/mvs/model_colmap.mvs \
    --output-file $DATASET_PATH/seq_0${seq}/output_ply/openmvs.ply
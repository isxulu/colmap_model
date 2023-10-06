#   CAMERA_ID, MODEL, WIDTH, HEIGHT, PARAMS[]
'''
1 PINHOLE 1600 1200 925.5456 922.6144 263.42592 198.10208
'''
###########################################################################################################
# 因为特征提取生成的 database 中图片的次序并不规则，则需先生成 databse，再根据其次序生成 images.txt                 #
# colmap request: Each image in images.txt must have the same image_id (first column) as in the database  #
###########################################################################################################
import numpy as np
import os
import sqlite3
import json

def get_intr(folder_path):
    current_dir = os.getcwd()
    db_path = os.path.join(folder_path, 'database.db')
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    '''
    cameras
    sqlite_sequence
    images
    keypoints
    descriptors
    matches
    two_view_geometries
    '''
    cursor.execute('SELECT * FROM images')
    result = cursor.fetchall()
    # for row in result:
    #     print(row)
    conn.close()

    intrinsic_matrixs = []
    output_lines = []
    for row in result:
        image_name = row[1]
        image_id = row[0]   # idx from 1 same with database.db not 0 
        json_path = os.path.join(folder_path, 'meta_data.json')
        with open(json_path, 'r') as file:
            json_data = json.load(file)

        camera_model = json_data['camera_model']
        w = json_data['width']
        h = json_data['height']

        intrinsic_matrix = []
        for frame in json_data["frames"]:
            if frame["rgb_path"] == image_name:
                intrinsic_matrix = frame["intrinsics"]
                break
        intrinsic_matrix = np.array(intrinsic_matrix)
        intrinsic_matrixs.append(intrinsic_matrix)

        fx = intrinsic_matrix[0, 0]
        fy = intrinsic_matrix[1, 1]
        cx = intrinsic_matrix[0, 2]
        cy = intrinsic_matrix[1, 2]

        cam_id = image_id

        # > output.file
        output_line = f"{cam_id} {camera_model} {w} {h} {fx} {fy} {cx} {cy}"
        output_lines.append(output_line)

    # 将结果隔行写入cameras.txt文件
    cam_path = os.path.join(folder_path, 'sparse_model/cameras.txt')
    with open(cam_path, 'w') as f:
        for line in output_lines:
            f.write(line + '\n')
    return intrinsic_matrixs

from write_cam import get_intr
from write_image import get_extr
import argparse


def main():
    parser = argparse.ArgumentParser(description='fulfill cameras.txt & images.txt under the sparse_model folder.')
    parser.add_argument('--path', type=str, help='the path of the seq0? folder.')
    args = parser.parse_args()

    np_cv_projs = get_intr(args.path)   # can be used to see the poses of cam in some visualizing tool
    np_w2cs = get_extr(args.path)

if __name__ == "__main__":

    main()
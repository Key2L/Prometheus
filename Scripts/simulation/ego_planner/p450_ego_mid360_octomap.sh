#!/usr/bin/env bash
# 脚本描述: P450 + MID360 + FAST-LIO + OctoMap + EGO 仿真

# 不依赖调用者当前终端是否已经 source 过工作空间环境。
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROMETHEUS_ROOT="$(cd -- "${SCRIPT_DIR}/../../.." && pwd)"

if [[ ! -f "${PROMETHEUS_ROOT}/devel/setup.bash" ]]; then
    echo "错误: 未找到 ${PROMETHEUS_ROOT}/devel/setup.bash，请先编译 Prometheus。" >&2
    exit 1
fi

# shellcheck disable=SC1091
source "${PROMETHEUS_ROOT}/devel/setup.bash"

# Prometheus 的 setup.bash 会重建 ROS_PACKAGE_PATH，因此需要在它之后
# 恢复同级 PX4 工作区及 Gazebo SITL 的运行环境。
PX4_ROOT="$(cd -- "${PROMETHEUS_ROOT}/.." && pwd)/prometheus_px4"
PX4_BUILD_ROOT="${PX4_ROOT}/build/amovlab_sitl_default"

export ROS_PACKAGE_PATH="${ROS_PACKAGE_PATH:+${ROS_PACKAGE_PATH}:}${PX4_ROOT}:${PX4_ROOT}/Tools/sitl_gazebo"
export GAZEBO_PLUGIN_PATH="${GAZEBO_PLUGIN_PATH:+${GAZEBO_PLUGIN_PATH}:}${PX4_BUILD_ROOT}/build_gazebo"
export GAZEBO_MODEL_PATH="${GAZEBO_MODEL_PATH:+${GAZEBO_MODEL_PATH}:}${PX4_ROOT}/Tools/sitl_gazebo/models"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${PX4_BUILD_ROOT}/build_gazebo"

missing_packages=()
for package in prometheus_gazebo prometheus_uav_control fast_lio plan_env octomap_server ego_planner rviz_plugins px4; do
    if ! rospack find "${package}" >/dev/null 2>&1; then
        missing_packages+=("${package}")
    fi
done

if (( ${#missing_packages[@]} > 0 )); then
    echo "错误: 缺少 ROS 包: ${missing_packages[*]}" >&2
    if [[ " ${missing_packages[*]} " == *" octomap_server "* ]]; then
        echo "请先执行: sudo apt-get install ros-noetic-octomap-server" >&2
    fi
    exit 1
fi

UAV_ID=1

gnome-terminal --window -e 'bash -c "roscore; exec bash"' \
--tab -e 'bash -c "sleep 3; roslaunch prometheus_gazebo sitl_indoor_1uav_P450_mid360.launch uav1_id:='$UAV_ID' uav1_init_x:=-0.0 uav1_init_y:=-0.0; exec bash"' \
--tab -e 'bash -c "sleep 4; roslaunch prometheus_uav_control uav_control_main_indoor_mid360.launch uav_id:='$UAV_ID'; exec bash"' \
--tab -e 'bash -c "sleep 4; roslaunch fast_lio mapping_mid360_gazebo.launch; exec bash"' \
--tab -e 'bash -c "sleep 3; roslaunch prometheus_gazebo mid360_to_octomap.launch; exec bash"' \
--tab -e 'bash -c "sleep 4; roslaunch ego_planner sitl_ego_octomap_mid360.launch; exec bash"' \


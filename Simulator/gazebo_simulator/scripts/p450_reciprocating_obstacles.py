#!/usr/bin/env python3
"""Drive the two cylinder models in the P450 planning world."""

import math

import rospy
from gazebo_msgs.msg import ModelState


def make_state(name, x, y, velocity_x, velocity_y):
    state = ModelState()
    state.model_name = name
    state.reference_frame = "world"
    state.pose.position.x = x
    state.pose.position.y = y
    state.pose.position.z = 0.0
    state.pose.orientation.w = 1.0
    state.twist.linear.x = velocity_x
    state.twist.linear.y = velocity_y
    return state


def main():
    rospy.init_node("p450_reciprocating_obstacles")
    publisher = rospy.Publisher("/gazebo/set_model_state", ModelState, queue_size=10)

    # 使用墙钟等待 Gazebo 建立订阅，避免 /use_sim_time 尚未发布时卡住。
    while not rospy.is_shutdown() and publisher.get_num_connections() == 0:
        rospy.rostime.wallsleep(0.1)

    start_time = rospy.Time.now().to_sec()
    rate = rospy.Rate(30)

    while not rospy.is_shutdown():
        elapsed = rospy.Time.now().to_sec() - start_time

        omega_x = 0.45
        x = 1.5 + 2.2 * math.sin(omega_x * elapsed)
        velocity_x = 2.2 * omega_x * math.cos(omega_x * elapsed)
        publisher.publish(make_state("dynamic_cylinder_x", x, 4.0, velocity_x, 0.0))

        omega_y = 0.38
        y = -1.0 + 2.4 * math.cos(omega_y * elapsed)
        velocity_y = -2.4 * omega_y * math.sin(omega_y * elapsed)
        publisher.publish(make_state("dynamic_cylinder_y", -4.0, y, 0.0, velocity_y))

        rate.sleep()


if __name__ == "__main__":
    main()

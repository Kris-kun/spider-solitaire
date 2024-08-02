extends Node

signal notification_added

enum NotificationType {
	HINT,
	HANDOUT,
}

const NOTIFICATION_RESOURCE = preload("res://general/nodes/notification.tscn")

var active_notifications: Array[NotificationType] = []


func add(type: NotificationType, text: String, anchor_node: Control, anchor: TransformUtils.Anchor) -> void:
	if active_notifications.has(type):
		return
	
	active_notifications.append(type)
	
	@warning_ignore("shadowed_variable_base_class")
	var notification: Notification = NOTIFICATION_RESOURCE.instantiate()
	notification.set_text(text)
	
	notification_added.emit(notification)
	
	notification.global_position = TransformUtils.get_global_position(anchor_node, anchor)
	notification.global_position -= notification.size * (Vector2(1.0, 1.0) - TransformUtils.get_anchor_position(anchor))
	
	await get_tree().create_timer(2.0).timeout
	
	active_notifications.erase(type)
	notification.queue_free()

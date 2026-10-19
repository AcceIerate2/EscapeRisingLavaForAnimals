return {
	OpenDistance = 5, -- studs from the middle of the doorway (ignoring height) that open the gate
	CloseDistance = 5, -- studs beyond which it closes again
	MaxHeightDifference = 8, -- players further above/below than this don't open it
	OpenAngle = 90, -- degrees when fully open
	SwingSpeed = 240, -- degrees per second the leaves swing at
	CheckInterval = 0.1, -- seconds between scans for new or removed gates
}

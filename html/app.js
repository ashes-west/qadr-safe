window.addEventListener('message', function(event) {
	const data = event.data;

	if (data.action === "showSafeHud") {
		document.getElementById('hud-container').style.display = "flex";
	}

	if (data.action === 'updateKeys') {
		toggleSafeKey('key-backspace', data.keys.backspace);
		toggleSafeKey('key-w', data.keys.w);
		toggleSafeKey('key-a', data.keys.a);
		toggleSafeKey('key-d', data.keys.d);
	}

	if (data.action === 'hideSafeHud') {
		document.getElementById('hud-container').style.display = "none";
	}
});

function toggleSafeKey(id, active) {
	const keyElement = document.getElementById(id);
	if (active) {
		keyElement.classList.add('active');
	} else {
		keyElement.classList.remove('active');
	}
}

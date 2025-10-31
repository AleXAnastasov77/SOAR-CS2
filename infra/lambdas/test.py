from pymisp import PyMISP

# === MISP Configuration ===
misp_url = "http://soc.innovatech.internal"
misp_key = "StptFPqvvEg6mGsQrP0FxXcVm6qq4UTJumypky2C"   # Automation key from your user profile
misp_verifycert = False       # set to True if using a valid certificate

# === Initialize MISP connection ===
misp = PyMISP(misp_url, misp_key, misp_verifycert, debug=False)

# === Search for IP ===
ip_to_check = "8.8.8.8"  # use a known malicious IP to test
r = misp.search(controller='attributes', value=ip_to_check)

# === Interpret results ===
if not r or "Attribute" not in r:
    print(f"{ip_to_check} not found in MISP.")
else:
    print(f"✅ {ip_to_check} found in MISP:")
    for attr in r["Attribute"]:
        event_info = attr.get("Event", {}).get("info", "No event info")
        print(f"- Category: {attr['category']}, Type: {attr['type']}")
        print(f"  Event: {event_info}")
        print(f"  To IDs: {attr['to_ids']}")
        print()

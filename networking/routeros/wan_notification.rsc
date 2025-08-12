# --- Variable Definitions ---
:local host "1.1.1.1"; # The IP address to ping for connectivity checks (e.g., a reliable public DNS server like Cloudflare's 1.1.1.1)
:local wan1 "ether1"; # Name of the first WAN interface to monitor
:local wan2 "lte1"; # Name of the second WAN interface to monitor
:local webhookURL ""; # The URL of the webhook to which status notifications will be sent

# --- Logic for WAN1 ---
:local newStatus1 "down"; # default to down; only promote on positive replies
:do {
    :if (([/ping address=$host interface=$wan1 count=5 interval=1s]) > 0) do={
        :set newStatus1 "up";
    }
} on-error={}

# --- Logic for WAN2 ---
:local newStatus2 "down"; # default to down; only promote on positive replies
:do {
    :if (([/ping address=$host interface=$wan2 count=5 interval=1s]) > 0) do={
        :set newStatus2 "up";
    }
} on-error={}

# Always send a single notification with the current status of both interfaces
:log info "WAN $wan1 is $newStatus1, WAN $wan2 is $newStatus2. Sending notification.";
# Use the :serialize function to create a valid JSON string
:local jsonData [:serialize to=json {"wan1_status"=$newStatus1; "wan2_status"=$newStatus2}];
# Build the HTTP header string separately
:local httpHeader "Content-Type:application/json";
# Pass the variables enclosed in quotes to ensure the parser treats them as single arguments
/tool fetch url="$webhookURL" http-data="$jsonData" http-header-field="$httpHeader" http-method=post;

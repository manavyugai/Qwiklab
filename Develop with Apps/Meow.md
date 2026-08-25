# Develop with Apps Script and AppSheet: Challenge Lab | ARC126


<blockquote style="background-color: #1e1e2e; color: #cdd6f4; border-left: 5px solid #89b4fa; border-radius: 8px; padding: 1.2em; font-family: sans-serif; font-size: 14px; line-height: 1.6; box-shadow: 0 4px 6px rgba(0,0,0,0.3);">
  <div style="color: #89b4fa; font-weight: bold; font-size: 16px; margin-bottom: 8px;">
    ℹ️ DISCLAIMER
  </div>
  <strong style="color: #f9e2af;">Educational Purpose Only:</strong> This script and guide are provided for educational purposes to help you understand lab services and boost your career. Please review the script before use to familiarize yourself with Google Cloud services.
  <br><br>
  <strong style="color: #f9e2af;">Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The goal is to enhance your learning experience — not to circumvent it.
</blockquote>

---

## ⚙️ **Task 2: Add Automation to an AppSheet App**

### 1. Open Drive👉 [Here](https://drive.google.com/drive/my-drive)
### 2. Download🔗 [Here](https://docs.google.com/spreadsheets/d/1nSa6SvRnecUgCOSEYO-0_hgE5r29P6J1/export?format=xlsx)

## 💬 **Task 3: Create and Publish an Apps Script Chat Bot**

Replace the following code in **Code.gs**:

```javascript
/**
 * Responds to a MESSAGE event in Google Chat.
 *
 * @param {Object} event the event object from Google Chat
 */
function onMessage(event) {
  var name = "";

  if (event.space.type == "DM") {
    name = "You";
  } else {
    name = event.user.displayName;
  }
  var message = name + " said \"" + event.message.text + "\"";

  return { "text": message };
}

/**
 * Responds to an ADDED_TO_SPACE event in Google Chat.
 *
 * @param {Object} event the event object from Google Chat
 */
function onAddToSpace(event) {
  var message = "";

  if (event.space.singleUserBotDm) {
    message = "Thank you for adding me to a DM, " + event.user.displayName + "!";
  } else {
    message = "Thank you for adding me to " +
        (event.space.displayName ? event.space.displayName : "this chat");
  }

  if (event.message) {
    message = message + " and you said: \"" + event.message.text + "\"";
  }
  console.log('Helper Bot added in ', event.space.name);
  return { "text": message };
}

/**
 * Responds to a REMOVED_FROM_SPACE event in Google Chat.
 *
 * @param {Object} event the event object from Google Chat
 */
function onRemoveFromSpace(event) {
  console.info("Bot removed from ",
      (event.space.name ? event.space.name : "this chat"));
}
```
---



---

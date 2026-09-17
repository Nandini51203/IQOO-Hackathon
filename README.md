# 🛡️ RakshaSense

### Your Phone as a Silent Guardian

RakshaSense is a phone-based personal safety and emergency response system designed to detect possible falls or accidents and automatically escalate an emergency when the user is unable to respond.

The current prototype uses the smartphone's built-in motion sensors to detect abnormal movement patterns and provides an automatic emergency response workflow.

---

## 🚨 Problem

Most emergency and safety applications assume that the user is conscious and able to manually trigger an SOS.

In situations such as:

- Road accidents
- Falls
- Sudden impacts
- Loss of consciousness
- Elderly people falling while alone

the victim may be unable to interact with their phone.

RakshaSense addresses this limitation by using the phone itself as a passive safety monitor.

---

# 💡 Solution

RakshaSense continuously monitors the smartphone's motion sensors after the user activates monitoring.

When a possible fall is detected:

```text
Motion Monitoring
       ↓
Fall Detection
       ↓
Possible Fall
       ↓
"Are You Okay?"
       ↓
User Responds?
   ↙           ↘
 YES            NO
  ↓              ↓
Resume       Emergency
Monitoring    Escalation
                 ↓
          Get GPS Location
                 ↓
          Automatic SMS

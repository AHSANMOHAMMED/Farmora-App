import urllib.request
import os

img_dir = r"c:\Users\Gowsikan Sivananthan\Desktop\Farmora-app\Farmora-App\assets\images"
os.makedirs(img_dir, exist_ok=True)

items = [
    ("https://lh3.googleusercontent.com/aida-public/AB6AXuAhj1jeTlvjjDQkt6WiQ6WOvVitY3SY6iuiOgJsJ_93gal24z5SvvfksLA4QcshsdxikA0KhpU4ZLDfk_UtO4lQPFGHjBLnVRhCl_NB2ZeMKi0-6qNuWprLQdwvOtDq304zCu7T7IEumYaIAGuVmFEP3GoGOuSIxSjMXDujytESWf6t-sHTGelRetsZwJAt7gCLUaBKB2zEWZpogOKa4vix-xTq9JWGE5Ou_YXCJwpzN5TYb3GVaqSY", os.path.join(img_dir, "farmora_logo.png")),
    ("https://lh3.googleusercontent.com/aida-public/AB6AXuCWQK6r3HTle8TrJdlYx_IRvkORZ_HJuo2MdggpAl9KHCY4Xot-t-vxPMxtJOnprs8FbdvOYOMiJBGMbDYV45LLgGG8QFNlx6gUy6TSgZxjVRg-WPDqNQfKBQw-Aj867nLL93DOXMArdxpZY11RUyoctOiy9R0Iv9KoeCELbo-65fuQjyxb8Hzy8PGHnZ9BI4fYf2bcdXk7sgqZ9REi-LoIqtAsW0hHDE591Ky_eeqQzLL8WlMmDnoo", os.path.join(img_dir, "farmer_headshot.png")),
    ("https://lh3.googleusercontent.com/aida-public/AB6AXuDdtaVvbvZ7-5QyGKsRXDHcmHZGNt9BHRMgfJhDwej66W8HPIuXh-ejAFMjYiIxr9Cb0LwHWVsRzahQHEydR0YEyhp8LJt1fQazce6sR7_U0XV3UoO8Fx9hkp53wJ-rB6OsoAWYfKd2_cxAvNUF9FV6SFNWZgfHnBiiX5XYRTijTQAtpPXaP-EAZRbRdmbVqAsfyUfPvilfhbUbApHmjQB4gqGNhZRF1CYiX29i8WcXMxHtPvUwOJwz", os.path.join(img_dir, "heirloom_tomatoes.png")),
    ("https://lh3.googleusercontent.com/aida-public/AB6AXuBmq8plUNSzqiT8Nt67cY7913_tRnM3o4TVQsYDi_k4_RVqb_Txz9wDG_lI8TrK0XEpC7-D8xabNkM1Wgb30Tb8FVNuaaM9_EXzr4y7biNCgzcPA2vJ-Y_4GNlPsyJwmEvQmY73mygGhn9ka1A9ApZl08vCe2YuELk5FBkuypVpfTMoF_eHpEdYQU-dHE_nUaYBby1D4-CciK4UEJq1FYf1aXAL1wxKCGackBpPs_QMe4sQYc2gpxKy", os.path.join(img_dir, "dinosaur_kale.png")),
    ("https://lh3.googleusercontent.com/aida-public/AB6AXuAVCwMcYy7EHkpHivdwewRrgeTkH5g2rq1NCnAJSgMpcHiNJ-Us3qETVY6cxei29WtwVfe2XfUCZpgaiRz9YHSWTyjgmHbjqFj7ynJo-cNjEJy_BcFpfJSPv29j099SwRysUBsbkfxM6fXRzGZ8cYicQZTUlShgCop1oWS1mJpYmvDJcQfwHDm35EHTdP4CvHiPWlWozxaO1ZqFWB9pJVVKiyG4ITl1RKZHZHJXTSR9_IWRgiY7TOlM", os.path.join(img_dir, "black_beauty_eggplant.png")),
    ("https://lh3.googleusercontent.com/aida-public/AB6AXuAjbIcBdWYBb9hzjMdX1lJgPxIhMXLgZef7y1IZGdpO5NPpT-8g4vMpZQvAHOE26SkPhfbzRSccsmmtbcvSGncTIw4ZLKayRttm2nhKroA3ElcOLP4AhkWq7Tq8Fh0j_rwyFGvUHIrrvDcNS5v6tu9-1-fu7eis8nBwVAwNT235PSKHHyfeI0CJCI6BGkn_HD7FSaQh4n5LKlysBRT2KuaMMNkd8y1VLVdxqkPGHOH_MFgT7Li7hE5N", os.path.join(img_dir, "nantes_carrots.png")),
    ("https://lh3.googleusercontent.com/aida-public/AB6AXuBzf_XxbVvLgB-JUZcpRCwNBg1fipm3FntYJ1TU14ercdO2Fgcnszb1_C0UViZ7y_44ZRTCH02a3NJzSoWHZGufb0oridG848Ew0pVPu6RCu7zhXpzM4Nh2LZ8qJ9daUAN0OAU2_Tt4B9tOpYKNI86fMSEBdyoQR4Twsl_1b9Is2VxV2PaEKlrU2t2xC-nmep5Bn9BCZj466LnHemkIlEHKJgtM9WKN8IYAoUEVGiS9ih4nrsijjSQw", os.path.join(img_dir, "cherry_tomatoes.png")),
    ("https://lh3.googleusercontent.com/aida-public/AB6AXuBXyKpDL7aGlAPypHcOsMagscRgDPvS6qHQr5MLgmrwBUix1Hok8UHxAJRAJZhHYR3UxBWmYqswFF0Agzwcg75o9E1BaS_be-FyOO-n2h-YJIL4T53X92sDUEjMVFvEtCXcGxuuSkyT-13Aq8dnx-OHwt-QkQyvkxSPfzLK1nkR031Pcb4mhMyESSVQ2WMACrjE2Qam_tVPgE8bte-TpOwuAPrKckFQBemKCAdpF1zBrW1lgU96uH5Q", os.path.join(img_dir, "romaine_lettuce.png")),
    ("https://lh3.googleusercontent.com/aida-public/AB6AXuB-DqONo9CgOlXY5FRtxY_VWPLNM4oBpT93QMLj2svhJOIg91gZgFCaNM84vHGbwj8jP8Mzy1PHg43SxpVBqyLD1vF7uGfcr3CVcajRqu-1c13JEi4AjYx7pseAZj1LabFjBoyiTX_f18rDn5TrOkb-ShaDd9ti5F62qUm5bSCmXWq9f3hdNyqCmDvpwtxbJePSTVmV4Fogh3i839FEnFdu5Pob_g8dkXwv2eJilfMQJbShh1meRuPH", os.path.join(img_dir, "buyer_sarah.png")),
    ("https://lh3.googleusercontent.com/aida-public/AB6AXuDhGjvzm6VlUm2SOl1wfHx3JY_qpPUYeWjSSlrwBHna51YkEzglESeXJsxzcNHKAcFDxzyYTr-05RSxhYLspNR2JDyvwaOl6mGeaVGNOwf4LFhEfsTYzBRTwiApWEGw5wg6XZKiexTMXhRUABp58WZA3qIiCvYEYFyZHl4LS-3rJibCRCnV5nBssmuy_2Vpv-SFAWuBpjz7qPfV_84hDnYKsZA0cHUpV0FVRpN3tfmtZMRMu_EOFhnA", os.path.join(img_dir, "roma_tomatoes_1.png")),
    ("https://lh3.googleusercontent.com/aida-public/AB6AXuCaOirBTzSzG3UjrFBCmaaxrefm9h4SGrC9_Xg8g2S1l2iARFjihq7wKXLo6bO6eDNIkursQ8t9qYqbAzky15NzCO1-naacHthvLw0VD8BrzZSAoFfaMnPK8TnXdb0RMSo1sJriI0vZDsaXmFljwnPyqMvqEpvMXfnMzIqvM7BmBW2fk1rAJ9CE6B9MqZ16g-dxa-QkILtExV-05tQjDTn_66gmlLOvzr2EILwT47QyIWN1LW3v8FTl", os.path.join(img_dir, "roma_tomatoes_2.png")),
    ("https://lh3.googleusercontent.com/aida-public/AB6AXuCQ0wxh0ooBh6v4Gg4oBcj26VgLfIFcz9cQfdiP13TErA9l8AiclXaBJKqu0ADyUPaA77GHMnFUOOblsMowHJ6RtGhtgneOmwsetumVawKGKLyawbr9VfAniXqL67JIq7qOGrCzcnV8WOFZTp5G5VzLQVqO0Ah6MgOSo1rjSyX1xJ228cYJuhps3RPWyoeVcZM-D-ENRUSTBVVcVF3kpAb4ySAT_Xbm6ArioPgYWRoGEStDJKo_7gPL", os.path.join(img_dir, "vehicle_blurry.png")),
]

req_headers = {"User-Agent": "Mozilla/5.0"}
for url, target_path in items:
    try:
        req = urllib.request.Request(url, headers=req_headers)
        with urllib.request.urlopen(req) as resp, open(target_path, "wb") as f:
            f.write(resp.read())
        print(f"Downloaded {os.path.basename(target_path)} ({os.path.getsize(target_path)} bytes)")
    except Exception as e:
        print(f"Failed {os.path.basename(target_path)}: {e}")

print("Done downloading all image assets.")

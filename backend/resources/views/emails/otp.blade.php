<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f4f4f4;
            padding: 20px;
        }

        .container {
            max-width: 500px;
            margin: auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
        }

        .otp {
            font-size: 32px;
            font-weight: bold;
            color: #0A1128;
            letter-spacing: 8px;
            text-align: center;
            padding: 20px;
            background: #f0f4ff;
            border-radius: 8px;
        }

        .footer {
            font-size: 12px;
            color: #888;
            margin-top: 20px;
        }
    </style>
</head>

<body>
    <div class="container">
        <h2>Halo Mahasiswa Polibatam! 👋</h2>
        <p>Ini kode OTP buat verifikasi akun Polibatam Ride:</p>
        <div class="otp">{{ $otp }}</div>
        <p>Kode ini berlaku selama <strong>5 menit</strong>. Jangan kasih ke siapapun ya!</p>
        <div class="footer">
            <p>Kalau anda tidak merasa minta kode ini, abaikan aja email ini.</p>
            <p>— Tim Polibatam Ride</p>
        </div>
    </div>
</body>

</html>
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\OtpMail;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    /**
     * LOGIN (bisa pake email ATAU username)
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|string',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $user = User::where('email', $request->email)
            ->orWhere('username', $request->email)
            ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Email/Username atau Password salah'], 401);
        }

        // Cek status verifikasi admin
        if ($user->status === 'pending') {
            return response()->json([
                'message' => 'Akun Anda masih menunggu verifikasi admin. Silakan cek email secara berkala.',
                'status' => 'pending',
            ], 403);
        }

        if ($user->status === 'rejected') {
            return response()->json([
                'message' => 'Maaf, akun Anda ditolak oleh admin. ' . ($user->admin_note ?? ''),
                'status' => 'rejected',
            ], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login berhasil',
            'token' => $token,
            'user' => $user,
        ], 200);
    }

    /**
     * KIRIM OTP (Register)
     */
    public function sendOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        // Cek kalau email udah terdaftar
        if (User::where('email', $request->email)->exists()) {
            return response()->json(['message' => 'Email sudah terdaftar'], 422);
        }

        $otp = rand(100000, 999999);
        Cache::put('otp_' . $request->email, $otp, now()->addMinutes(5));

        try {
            Mail::to($request->email)->send(new OtpMail($otp));
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Gagal kirim OTP ke email.',
                'error' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'message' => 'OTP berhasil dikirim ke email',
            'otp_debug' => config('app.debug') ? $otp : null,
        ], 200);
    }

    /**
     * REGISTER (dengan upload KTM)
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'username' => 'required|string|unique:users,username',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:8',
            'otp' => 'required|string',
            'nim' => 'nullable|string',
            'ktm_file' => 'required|file|mimes:jpg,jpeg,png,pdf|max:5120', // max 5MB
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        // Cek OTP
        $cachedOtp = Cache::get('otp_' . $request->email);
        if (!$cachedOtp || $cachedOtp != $request->otp) {
            return response()->json(['message' => 'Kode OTP salah atau sudah kadaluarsa'], 400);
        }

        // Simpan file KTM
        $ktmPath = null;
        if ($request->hasFile('ktm_file')) {
            $ktmPath = $request->file('ktm_file')->store('ktm', 'public');
        }

        // Bikin user dengan status PENDING
        $user = User::create([
            'name' => $request->username,
            'username' => $request->username,
            'email' => $request->email,
            'nim' => $request->nim,
            'ktm_path' => $ktmPath,
            'password' => Hash::make($request->password),
            'status' => 'pending',
        ]);

        Cache::forget('otp_' . $request->email);

        return response()->json([
            'message' => 'Registrasi berhasil! Akun Anda menunggu verifikasi admin.',
            'user' => $user,
        ], 201);
    }

    /**
     * LOGOUT
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logout berhasil'], 200);
    }

    /**
     * FORGOT PASSWORD - KIRIM OTP
     */
    public function forgotPasswordSendOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $user = User::where('email', $request->email)->first();
        if (!$user) {
            return response()->json(['message' => 'Email tidak terdaftar'], 404);
        }

        $otp = rand(100000, 999999);
        Cache::put('forgot_otp_' . $request->email, $otp, now()->addMinutes(5));

        try {
            Mail::to($request->email)->send(new OtpMail($otp));
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Gagal kirim OTP ke email.',
                'error' => $e->getMessage(),
            ], 500);
        }

        return response()->json([
            'message' => 'OTP berhasil dikirim ke email',
            'otp_debug' => config('app.debug') ? $otp : null,
        ], 200);
    }

    /**
     * FORGOT PASSWORD - RESET
     */
    public function forgotPasswordReset(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'otp' => 'required|string',
            'password' => 'required|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $cachedOtp = Cache::get('forgot_otp_' . $request->email);
        if (!$cachedOtp || $cachedOtp != $request->otp) {
            return response()->json(['message' => 'Kode OTP salah atau sudah kadaluarsa'], 400);
        }

        $user = User::where('email', $request->email)->first();
        if (!$user) {
            return response()->json(['message' => 'User tidak ditemukan'], 404);
        }

        $user->update(['password' => Hash::make($request->password)]);
        Cache::forget('forgot_otp_' . $request->email);

        return response()->json(['message' => 'Password berhasil diubah. Silakan login.'], 200);
    }
}
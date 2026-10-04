<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class ProfileController extends Controller
{
    /**
     * GET PROFILE
     * Endpoint: GET /api/profile
     */
    public function show(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'user' => $this->formatUser($user),
        ], 200);
    }

    /**
     * UPDATE PROFILE
     * Endpoint: POST /api/profile/update
     */
    public function update(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:100',
            'phone' => 'nullable|string|max:20',
            'is_runner' => 'nullable|boolean',
            'vehicle_type' => 'nullable|string|max:50',
            'vehicle_plate' => 'nullable|string|max:20',
            'profile_photo' => 'nullable|file|mimes:jpg,jpeg,png|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        // Kalau jadi runner, wajib isi detail kendaraan
        $isRunner = filter_var($request->is_runner, FILTER_VALIDATE_BOOLEAN);
        if ($isRunner) {
            if (empty($request->vehicle_type) || empty($request->vehicle_plate)) {
                return response()->json([
                    'message' => 'Detail kendaraan wajib diisi untuk Runner',
                ], 422);
            }
        }

        // Update foto profile kalau ada
        if ($request->hasFile('profile_photo')) {
            // Hapus foto lama
            if ($user->profile_photo && Storage::disk('public')->exists($user->profile_photo)) {
                Storage::disk('public')->delete($user->profile_photo);
            }
            $photoPath = $request->file('profile_photo')->store('profile', 'public');
            $user->profile_photo = $photoPath;
        }

        $user->name = $request->name;
        $user->phone = $request->phone;
        $user->is_runner = $isRunner;
        $user->vehicle_type = $isRunner ? $request->vehicle_type : null;
        $user->vehicle_plate = $isRunner ? $request->vehicle_plate : null;
        $user->save();

        return response()->json([
            'message' => 'Profil berhasil diperbarui',
            'user' => $this->formatUser($user),
        ], 200);
    }

    private function formatUser($user)
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'username' => $user->username,
            'email' => $user->email,
            'nim' => $user->nim,
            'phone' => $user->phone,
            'profile_photo' => $user->profile_photo,
            'profile_photo_url' => $user->profile_photo
                ? asset('storage/' . $user->profile_photo)
                : null,
            'status' => $user->status,
            'is_runner' => (bool) $user->is_runner,
            'vehicle_type' => $user->vehicle_type,
            'vehicle_plate' => $user->vehicle_plate,
            'rating_as_driver' => (float) $user->rating_as_driver,
            'rating_as_requester' => (float) $user->rating_as_requester,
            'total_trips' => (int) $user->total_trips,
        ];
    }
}
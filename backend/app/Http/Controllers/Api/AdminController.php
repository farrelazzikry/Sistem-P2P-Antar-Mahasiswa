<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    // Cek apakah user beneran admin
    private function checkAdmin(Request $request)
    {
        if (!$request->user()->is_admin) {
            abort(403, 'Akses ditolak. Anda bukan Admin.');
        }
    }

    // List semua user (bisa difilter ?status=pending)
    public function getUsers(Request $request)
    {
        $this->checkAdmin($request);

        // HANYA AMBIL USER YANG BUKAN ADMIN
        $query = User::where('is_admin', false)->orderBy('created_at', 'desc');
        
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        return response()->json(['data' => $query->get()], 200);
    }

    // Approve User
    public function approveUser(Request $request, $id)
    {
        $this->checkAdmin($request);

        $user = User::find($id);
        if (!$user)
            return response()->json(['message' => 'User tidak ditemukan'], 404);

        $user->update(['status' => 'approved']);
        return response()->json(['message' => 'User berhasil di-approve'], 200);
    }

    // Reject User
    public function rejectUser(Request $request, $id)
    {
        $this->checkAdmin($request);

        $user = User::find($id);
        if (!$user)
            return response()->json(['message' => 'User tidak ditemukan'], 404);

        $user->update(['status' => 'rejected']);
        return response()->json(['message' => 'User berhasil di-reject'], 200);
    }

    // Reset Password User
    public function resetPassword(Request $request, $id)
    {
        $this->checkAdmin($request);

        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'new_password' => 'required|min:8',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $user = User::find($id);
        if (!$user)
            return response()->json(['message' => 'User tidak ditemukan'], 404);

        $user->update([
            'password' => \Illuminate\Support\Facades\Hash::make($request->new_password)
        ]);

        return response()->json(['message' => 'Password user berhasil direset'], 200);
    }
}
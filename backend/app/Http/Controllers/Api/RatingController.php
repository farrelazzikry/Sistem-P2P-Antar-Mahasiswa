<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Jastip;
use App\Models\Tebengan;
use App\Models\Rating;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class RatingController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'rateable_type' => 'required|in:jastip,tebengan',
            'rateable_id' => 'required|integer',
            'stars' => 'required|integer|min:1|max:5',
            'review' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $user = $request->user();

        // Resolve rateable
        if ($request->rateable_type === 'jastip') {
            $rateable = Jastip::find($request->rateable_id);
            $rateableClass = Jastip::class;
        } elseif ($request->rateable_type === 'tebengan') {
            $rateable = Tebengan::find($request->rateable_id);
            $rateableClass = Tebengan::class;
        } else {
            return response()->json(['message' => 'Tipe rating belum didukung'], 400);
        }

        if (!$rateable) {
            return response()->json(['message' => 'Order tidak ditemukan'], 404);
        }

        if ($rateable->status !== 'done') {
            return response()->json(['message' => 'Order belum selesai'], 400);
        }

        $isRequester = $rateable->requester_id === $user->id;
        $isRunner = $rateable->runner_id === $user->id;

        if (!$isRequester && !$isRunner) {
            return response()->json(['message' => 'Anda tidak berhak memberi rating'], 403);
        }

        if ($isRequester) {
            $rateeId = $rateable->runner_id;
            $role = 'driver';
        } else {
            $rateeId = $rateable->requester_id;
            $role = 'requester';
        }

        if (!$rateeId) {
            return response()->json(['message' => 'Tidak ada pihak untuk dinilai'], 400);
        }

        $existing = Rating::where('rater_id', $user->id)
            ->where('rateable_type', $rateableClass)
            ->where('rateable_id', $rateable->id)
            ->first();

        if ($existing) {
            return response()->json(['message' => 'Anda sudah memberi rating untuk order ini'], 400);
        }

        $rating = Rating::create([
            'rater_id' => $user->id,
            'ratee_id' => $rateeId,
            'rateable_type' => $rateableClass,
            'rateable_id' => $rateable->id,
            'stars' => $request->stars,
            'review' => $request->review,
            'role' => $role,
        ]);

        $this->updateUserRating($rateeId, $role);

        return response()->json([
            'message' => 'Rating berhasil dikirim',
            'data' => $rating,
        ], 201);
    }

    private function updateUserRating($userId, $role)
    {
        $avgStars = Rating::where('ratee_id', $userId)
            ->where('role', $role)
            ->avg('stars') ?? 0;

        $user = User::find($userId);
        if (!$user) return;

        if ($role === 'driver') {
            $user->update(['rating_as_driver' => round($avgStars, 2)]);
        } elseif ($role === 'requester') {
            $user->update(['rating_as_requester' => round($avgStars, 2)]);
        }
    }

    public function status(Request $request, $type, $id)
    {
        $user = $request->user();

        if ($type === 'jastip') {
            $rateable = Jastip::find($id);
            $rateableClass = Jastip::class;
        } elseif ($type === 'tebengan') {
            $rateable = Tebengan::find($id);
            $rateableClass = Tebengan::class;
        } else {
            return response()->json(['message' => 'Tipe rating belum didukung'], 400);
        }

        if (!$rateable) {
            return response()->json(['message' => 'Order tidak ditemukan'], 404);
        }

        $requesterRated = Rating::where('rateable_type', $rateableClass)
            ->where('rateable_id', $id)
            ->where('rater_id', $rateable->requester_id)
            ->exists();

        $runnerRated = Rating::where('rateable_type', $rateableClass)
            ->where('rateable_id', $id)
            ->where('rater_id', $rateable->runner_id)
            ->exists();

        $userHasRated = Rating::where('rateable_type', $rateableClass)
            ->where('rateable_id', $id)
            ->where('rater_id', $user->id)
            ->exists();

        return response()->json([
            'requester_rated' => $requesterRated,
            'runner_rated' => $runnerRated,
            'user_has_rated' => $userHasRated,
            'can_rate' => $rateable->status === 'done' && !$userHasRated,
        ], 200);
    }
}
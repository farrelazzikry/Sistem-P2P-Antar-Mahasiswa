<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Tebengan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class TebenganController extends Controller
{
    /**
     * LIST FEED TEBENGAN
     * GET /api/tebengans?status=open
     */
    public function index(Request $request)
    {
        $query = Tebengan::with(['requester:id,name,username,profile_photo'])
            ->orderBy('created_at', 'desc');

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $tebengans = $query->paginate(20);

        return response()->json([
            'data' => $tebengans->items(),
            'meta' => [
                'current_page' => $tebengans->currentPage(),
                'last_page' => $tebengans->lastPage(),
                'total' => $tebengans->total(),
            ],
        ], 200);
    }

    /**
     * DETAIL
     */
    public function show(Request $request, $id)
    {
        $tebengan = Tebengan::with([
            'requester:id,name,username,profile_photo,phone',
            'runner:id,name,username,profile_photo,phone',
        ])->find($id);

        if (!$tebengan) {
            return response()->json(['message' => 'Tebengan tidak ditemukan'], 404);
        }

        return response()->json(['data' => $tebengan], 200);
    }

    /**
     * BUAT TEBENGAN
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'pickup_location' => 'required|string|max:150',
            'destination' => 'required|string|max:150',
            'departure_time' => 'required|date|after:now',
            'budget' => 'required|numeric|min:1000',
            'fee' => 'nullable|numeric|min:0',
            'whatsapp_number' => 'required|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $tebengan = Tebengan::create([
            'requester_id' => $request->user()->id,
            'pickup_location' => $request->pickup_location,
            'destination' => $request->destination,
            'departure_time' => $request->departure_time,
            'budget' => $request->budget,
            'fee' => $request->fee ?? 0,
            'whatsapp_number' => $request->whatsapp_number,
            'status' => 'open',
        ]);

        return response()->json([
            'message' => 'Tebengan berhasil dibuat',
            'data' => $tebengan->load('requester:id,name,username,profile_photo'),
        ], 201);
    }

    /**
     * AMBIL TEBENGAN (RUNNER)
     */
    public function take(Request $request, $id)
    {
        $user = $request->user();

        if (!$user->is_runner) {
            return response()->json([
                'message' => 'Anda harus jadi Runner dulu.',
            ], 403);
        }

        $tebengan = Tebengan::find($id);
        if (!$tebengan) {
            return response()->json(['message' => 'Tebengan tidak ditemukan'], 404);
        }

        if ($tebengan->status !== 'open') {
            return response()->json(['message' => 'Tebengan sudah diambil orang lain'], 400);
        }

        if ($tebengan->requester_id === $user->id) {
            return response()->json(['message' => 'Anda tidak bisa ambil tebengan sendiri'], 400);
        }

        $tebengan->update([
            'runner_id' => $user->id,
            'status' => 'taken',
        ]);

        return response()->json([
            'message' => 'Tebengan berhasil diambil',
            'data' => $tebengan->load(['requester:id,name,username,phone']),
        ], 200);
    }

    /**
     * UPDATE STATUS
     */
    public function updateStatus(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:on_progress,done,cancelled',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $tebengan = Tebengan::find($id);
        if (!$tebengan) {
            return response()->json(['message' => 'Tebengan tidak ditemukan'], 404);
        }

        $user = $request->user();
        $isRequester = $tebengan->requester_id === $user->id;
        $isRunner = $tebengan->runner_id === $user->id;

        if (!$isRequester && !$isRunner) {
            return response()->json(['message' => 'Anda tidak berhak update'], 403);
        }

        $newStatus = $request->status;

        if ($newStatus === 'on_progress') {
            if (!$isRunner) {
                return response()->json(['message' => 'Hanya Runner yang bisa memulai'], 403);
            }
            if ($tebengan->status !== 'taken') {
                return response()->json(['message' => 'Tebengan belum diambil'], 400);
            }
        } elseif ($newStatus === 'done') {
            if (!$isRequester) {
                return response()->json(['message' => 'Hanya Pemesan yang bisa menyelesaikan'], 403);
            }
            if ($tebengan->status !== 'on_progress') {
                return response()->json(['message' => 'Tebengan belum dimulai'], 400);
            }
        } elseif ($newStatus === 'cancelled') {
            if (!$isRunner) {
                return response()->json(['message' => 'Hanya Runner yang bisa cancel'], 403);
            }
            if (!in_array($tebengan->status, ['taken', 'on_progress'])) {
                return response()->json(['message' => 'Tebengan belum diambil'], 400);
            }
        }

        $tebengan->update(['status' => $newStatus]);

        return response()->json([
            'message' => 'Status berhasil diupdate',
            'data' => $tebengan,
        ], 200);
    }

    /**
     * MY ORDERS
     */
    public function myOrders(Request $request)
    {
        $user = $request->user();
        $activeStatuses = ['open', 'taken', 'on_progress'];

        $myRequests = Tebengan::with('runner:id,name,username,profile_photo')
            ->where('requester_id', $user->id)
            ->where(function ($q) use ($activeStatuses, $user) {
                $q->whereIn('status', $activeStatuses)
                  ->orWhere(function ($q2) use ($user) {
                      $q2->where('status', 'done')
                         ->whereDoesntHave('ratings', function ($q3) use ($user) {
                             $q3->where('rater_id', $user->id);
                         });
                  });
            })
            ->orderBy('created_at', 'desc')
            ->get();

        $myTasks = Tebengan::with('requester:id,name,username,profile_photo')
            ->where('runner_id', $user->id)
            ->where(function ($q) use ($activeStatuses, $user) {
                $q->whereIn('status', $activeStatuses)
                  ->orWhere(function ($q2) use ($user) {
                      $q2->where('status', 'done')
                         ->whereDoesntHave('ratings', function ($q3) use ($user) {
                             $q3->where('rater_id', $user->id);
                         });
                  });
            })
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'my_requests' => $myRequests,
            'my_tasks' => $myTasks,
        ], 200);
    }

    /**
     * HISTORY
     */
    public function history(Request $request)
    {
        $user = $request->user();

        $filter = function ($q) use ($user) {
            $q->where('status', 'cancelled')
              ->orWhere(function ($q2) use ($user) {
                  $q2->where('status', 'done')
                     ->whereHas('ratings', function ($q3) use ($user) {
                         $q3->where('rater_id', $user->id);
                     });
              });
        };

        $asRequester = Tebengan::with('runner:id,name,username,profile_photo')
            ->where('requester_id', $user->id)
            ->where($filter)
            ->orderBy('updated_at', 'desc')
            ->get();

        $asRunner = Tebengan::with('requester:id,name,username,profile_photo')
            ->where('runner_id', $user->id)
            ->where($filter)
            ->orderBy('updated_at', 'desc')
            ->get();

        return response()->json([
            'as_requester' => $asRequester,
            'as_runner' => $asRunner,
        ], 200);
    }
}
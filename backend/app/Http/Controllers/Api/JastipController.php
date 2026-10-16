<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Jastip;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class JastipController extends Controller
{
    /**
     * LIST FEED JASTIP
     * GET /api/jastips
     * Query param: ?status=open (opsional)
     */
    public function index(Request $request)
    {
        $query = Jastip::with(['requester:id,name,username,profile_photo'])
            ->orderBy('created_at', 'desc');

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $jastips = $query->paginate(20);

        return response()->json([
            'data' => $jastips->items(),
            'meta' => [
                'current_page' => $jastips->currentPage(),
                'last_page' => $jastips->lastPage(),
                'total' => $jastips->total(),
            ],
        ], 200);
    }

    /**
     * DETAIL JASTIP
     * GET /api/jastips/{id}
     */
    public function show(Request $request, $id)
    {
        $jastip = Jastip::with([
            'requester:id,name,username,profile_photo,phone',
            'runner:id,name,username,profile_photo,phone',
        ])->find($id);

        if (!$jastip) {
            return response()->json(['message' => 'Order tidak ditemukan'], 404);
        }

        return response()->json(['data' => $jastip], 200);
    }

    /**
     * BUAT ORDER JASTIP
     * POST /api/jastips
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'item_name' => 'required|string|max:100',
            'item_description' => 'nullable|string|max:500',
            'buy_location' => 'required|string|max:150',
            'delivery_location' => 'required|string|max:150',
            'budget' => 'required|numeric|min:1000',
            'fee' => 'nullable|numeric|min:0',
            'whatsapp_number' => 'required|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $jastip = Jastip::create([
            'requester_id' => $request->user()->id,
            'item_name' => $request->item_name,
            'item_description' => $request->item_description,
            'buy_location' => $request->buy_location,
            'delivery_location' => $request->delivery_location,
            'budget' => $request->budget,
            'fee' => $request->fee ?? 0,
            'whatsapp_number' => $request->whatsapp_number,
            'status' => 'open',
        ]);

        return response()->json([
            'message' => 'Order jastip berhasil dibuat',
            'data' => $jastip->load('requester:id,name,username,profile_photo'),
        ], 201);
    }

    /**
     * AMBIL ORDER (RUNNER)
     * POST /api/jastips/{id}/take
     */
    public function take(Request $request, $id)
    {
        $user = $request->user();

        if (!$user->is_runner) {
            return response()->json([
                'message' => 'Anda harus jadi Runner dulu. Tambahkan data kendaraan di profil.',
            ], 403);
        }

        $jastip = Jastip::find($id);

        if (!$jastip) {
            return response()->json(['message' => 'Order tidak ditemukan'], 404);
        }

        if ($jastip->status !== 'open') {
            return response()->json(['message' => 'Order sudah diambil orang lain'], 400);
        }

        if ($jastip->requester_id === $user->id) {
            return response()->json(['message' => 'Anda tidak bisa ambil order sendiri'], 400);
        }

        $jastip->update([
            'runner_id' => $user->id,
            'status' => 'taken',
        ]);

        return response()->json([
            'message' => 'Order berhasil diambil',
            'data' => $jastip->load(['requester:id,name,username,phone']),
        ], 200);
    }

    /**
     * UPDATE STATUS
     * POST /api/jastips/{id}/status
     * Body: { status: 'on_progress' | 'done' | 'cancelled' }
     */
        public function updateStatus(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:on_progress,done,cancelled',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $jastip = Jastip::find($id);
        if (!$jastip) {
            return response()->json(['message' => 'Order tidak ditemukan'], 404);
        }

        $user = $request->user();
        $isRequester = $jastip->requester_id === $user->id;
        $isRunner = $jastip->runner_id === $user->id;

        if (!$isRequester && !$isRunner) {
            return response()->json(['message' => 'Anda tidak berhak update order ini'], 403);
        }

        $newStatus = $request->status;

        // VALIDASI TRANSISI STATUS
        if ($newStatus === 'on_progress') {
            if (!$isRunner) {
                return response()->json(['message' => 'Hanya Runner yang bisa memulai order'], 403);
            }
            if ($jastip->status !== 'taken') {
                return response()->json(['message' => 'Order belum diambil'], 400);
            }
        } elseif ($newStatus === 'done') {
            // HANYA REQUESTER yang bisa selesaikan
            if (!$isRequester) {
                return response()->json(['message' => 'Hanya Pemesan yang bisa menyelesaikan order'], 403);
            }
            if ($jastip->status !== 'on_progress') {
                return response()->json(['message' => 'Order belum dimulai oleh Runner'], 400);
            }
        } elseif ($newStatus === 'cancelled') {
            // HANYA RUNNER yang bisa minta cancel (setelah ambil order)
            if (!$isRunner) {
                return response()->json(['message' => 'Hanya Runner yang bisa minta cancel'], 403);
            }
            if (!in_array($jastip->status, ['taken', 'on_progress'])) {
                return response()->json(['message' => 'Order belum diambil'], 400);
            }
        }

        $jastip->update(['status' => $newStatus]);

        return response()->json([
            'message' => 'Status berhasil diupdate',
            'data' => $jastip,
        ], 200);
    }
    /**
     * MY ORDERS
     * GET /api/jastips/my-orders
     */
    public function myOrders(Request $request)
    {
        $user = $request->user();

        $myRequests = Jastip::with('runner:id,name,username,profile_photo')
            ->where('requester_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();

        $myTasks = Jastip::with('requester:id,name,username,profile_photo')
            ->where('runner_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'my_requests' => $myRequests,
            'my_tasks' => $myTasks,
        ], 200);
    }
}
<?php
namespace App\Notifications;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class NewOrderNotification extends Notification
{
    use Queueable;
    public $orderType; // 'jastip' atau 'tebengan'
    public $itemName;

    public function __construct($orderType, $itemName)
    {
        $this->orderType = $orderType;
        $this->itemName = $itemName;
    }

    public function via(object $notifiable): array
    {
        return ['database']; // Simpan di DB
    }

    public function toArray(object $notifiable): array
    {
        return [
            'title' => 'Pesanan Baru Masuk!',
            'message' => "Ada order {$this->orderType} baru: {$this->itemName}. Buruan ambil!",
            'type' => 'new_order',
        ];
    }
}
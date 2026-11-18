<?php
namespace App\Notifications;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class OrderTakenNotification extends Notification
{
    use Queueable;
    public $runnerName;
    public $orderType;

    public function __construct($runnerName, $orderType)
    {
        $this->runnerName = $runnerName;
        $this->orderType = $orderType;
    }

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'title' => 'Pesanan Diambil',
            'message' => "Pesanan {$this->orderType} kamu telah diambil oleh {$this->runnerName}. Silakan cek WhatsApp!",
            'type' => 'order_taken',
        ];
    }
}
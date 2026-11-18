<?php
namespace App\Notifications;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class ReviewReminderNotification extends Notification
{
    use Queueable;
    public $orderType;

    public function __construct($orderType)
    {
        $this->orderType = $orderType;
    }

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'title' => 'Pengingat Pesanan',
            'message' => "Pesanan {$this->orderType} kamu sudah dimulai lebih dari 1 jam. Jangan lupa selesaikan dan beri rating ya!",
            'type' => 'reminder',
        ];
    }
}
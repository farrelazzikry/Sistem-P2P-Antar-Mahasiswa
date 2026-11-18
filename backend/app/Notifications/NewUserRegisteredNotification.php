<?php
namespace App\Notifications;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class NewUserRegisteredNotification extends Notification
{
    use Queueable;
    public $newUser;

    public function __construct($newUser)
    {
        $this->newUser = $newUser;
    }

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'title' => 'Mahasiswa Baru Mendaftar!',
            'message' => "{$this->newUser->name} ({$this->newUser->nim}) baru saja mendaftar. Segera verifikasi KTM-nya.",
            'type' => 'new_user',
        ];
    }
}
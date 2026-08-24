<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Validation Language Lines
    |--------------------------------------------------------------------------
    |
    | Terjemahan Bahasa Indonesia untuk pesan error validator bawaan Laravel.
    | APP_LOCALE di project ini di-set ke "id", jadi file ini wajib ada --
    | tanpa file ini Laravel tidak punya string apa pun untuk locale "id"
    | dan trans() mengembalikan key mentah ("validation.required") ke client.
    |
    */

    'accepted' => 'Kolom :attribute wajib disetujui.',
    'accepted_if' => 'Kolom :attribute wajib disetujui apabila :other adalah :value.',
    'active_url' => 'Kolom :attribute wajib berupa URL yang valid.',
    'after' => 'Kolom :attribute wajib berupa tanggal setelah :date.',
    'after_or_equal' => 'Kolom :attribute wajib berupa tanggal setelah atau sama dengan :date.',
    'alpha' => 'Kolom :attribute hanya boleh berisi huruf.',
    'alpha_dash' => 'Kolom :attribute hanya boleh berisi huruf, angka, strip, dan garis bawah.',
    'alpha_num' => 'Kolom :attribute hanya boleh berisi huruf dan angka.',
    'any_of' => 'Kolom :attribute tidak valid.',
    'array' => 'Kolom :attribute wajib berupa array.',
    'ascii' => 'Kolom :attribute hanya boleh berisi karakter alfanumerik dan simbol satu byte.',
    'before' => 'Kolom :attribute wajib berupa tanggal sebelum :date.',
    'before_or_equal' => 'Kolom :attribute wajib berupa tanggal sebelum atau sama dengan :date.',
    'between' => [
        'array' => 'Kolom :attribute wajib memiliki :min hingga :max item.',
        'file' => 'Kolom :attribute wajib berukuran :min hingga :max kilobyte.',
        'numeric' => 'Kolom :attribute wajib bernilai :min hingga :max.',
        'string' => 'Kolom :attribute wajib terdiri dari :min hingga :max karakter.',
    ],
    'boolean' => 'Kolom :attribute wajib bernilai benar atau salah.',
    'can' => 'Kolom :attribute berisi nilai yang tidak diizinkan.',
    'confirmed' => 'Konfirmasi :attribute tidak cocok.',
    'contains' => 'Kolom :attribute kekurangan nilai yang wajib diisi.',
    'current_password' => 'Password salah.',
    'date' => 'Kolom :attribute wajib berupa tanggal yang valid.',
    'date_equals' => 'Kolom :attribute wajib berupa tanggal yang sama dengan :date.',
    'date_format' => 'Kolom :attribute wajib sesuai format :format.',
    'decimal' => 'Kolom :attribute wajib memiliki :decimal angka desimal.',
    'declined' => 'Kolom :attribute wajib ditolak.',
    'declined_if' => 'Kolom :attribute wajib ditolak apabila :other adalah :value.',
    'different' => 'Kolom :attribute dan :other wajib berbeda.',
    'digits' => 'Kolom :attribute wajib :digits digit.',
    'digits_between' => 'Kolom :attribute wajib :min hingga :max digit.',
    'dimensions' => 'Kolom :attribute memiliki dimensi gambar yang tidak valid.',
    'distinct' => 'Kolom :attribute memiliki nilai duplikat.',
    'doesnt_contain' => 'Kolom :attribute tidak boleh berisi salah satu dari: :values.',
    'doesnt_end_with' => 'Kolom :attribute tidak boleh diakhiri dengan salah satu dari: :values.',
    'doesnt_start_with' => 'Kolom :attribute tidak boleh diawali dengan salah satu dari: :values.',
    'email' => 'Kolom :attribute wajib berupa alamat email yang valid.',
    'encoding' => 'Kolom :attribute wajib menggunakan encoding :encoding.',
    'ends_with' => 'Kolom :attribute wajib diakhiri dengan salah satu dari: :values.',
    'enum' => ':attribute yang dipilih tidak valid.',
    'exists' => ':attribute yang dipilih tidak valid.',
    'extensions' => 'Kolom :attribute wajib memiliki salah satu ekstensi berikut: :values.',
    'file' => 'Kolom :attribute wajib berupa file.',
    'filled' => 'Kolom :attribute wajib diisi.',
    'gt' => [
        'array' => 'Kolom :attribute wajib memiliki lebih dari :value item.',
        'file' => 'Kolom :attribute wajib lebih besar dari :value kilobyte.',
        'numeric' => 'Kolom :attribute wajib lebih besar dari :value.',
        'string' => 'Kolom :attribute wajib lebih dari :value karakter.',
    ],
    'gte' => [
        'array' => 'Kolom :attribute wajib memiliki :value item atau lebih.',
        'file' => 'Kolom :attribute wajib lebih besar atau sama dengan :value kilobyte.',
        'numeric' => 'Kolom :attribute wajib lebih besar atau sama dengan :value.',
        'string' => 'Kolom :attribute wajib lebih besar atau sama dengan :value karakter.',
    ],
    'hex_color' => 'Kolom :attribute wajib berupa warna heksadesimal yang valid.',
    'image' => 'Kolom :attribute wajib berupa gambar.',
    'in' => ':attribute yang dipilih tidak valid.',
    'in_array' => 'Kolom :attribute wajib ada di dalam :other.',
    'in_array_keys' => 'Kolom :attribute wajib berisi setidaknya salah satu key berikut: :values.',
    'integer' => 'Kolom :attribute wajib berupa angka bulat.',
    'ip' => 'Kolom :attribute wajib berupa alamat IP yang valid.',
    'ipv4' => 'Kolom :attribute wajib berupa alamat IPv4 yang valid.',
    'ipv6' => 'Kolom :attribute wajib berupa alamat IPv6 yang valid.',
    'json' => 'Kolom :attribute wajib berupa string JSON yang valid.',
    'list' => 'Kolom :attribute wajib berupa list.',
    'lowercase' => 'Kolom :attribute wajib huruf kecil.',
    'lt' => [
        'array' => 'Kolom :attribute wajib memiliki kurang dari :value item.',
        'file' => 'Kolom :attribute wajib kurang dari :value kilobyte.',
        'numeric' => 'Kolom :attribute wajib kurang dari :value.',
        'string' => 'Kolom :attribute wajib kurang dari :value karakter.',
    ],
    'lte' => [
        'array' => 'Kolom :attribute tidak boleh memiliki lebih dari :value item.',
        'file' => 'Kolom :attribute wajib kurang dari atau sama dengan :value kilobyte.',
        'numeric' => 'Kolom :attribute wajib kurang dari atau sama dengan :value.',
        'string' => 'Kolom :attribute wajib kurang dari atau sama dengan :value karakter.',
    ],
    'mac_address' => 'Kolom :attribute wajib berupa alamat MAC yang valid.',
    'max' => [
        'array' => 'Kolom :attribute tidak boleh memiliki lebih dari :max item.',
        'file' => 'Kolom :attribute tidak boleh lebih besar dari :max kilobyte.',
        'numeric' => 'Kolom :attribute tidak boleh lebih besar dari :max.',
        'string' => 'Kolom :attribute tidak boleh lebih dari :max karakter.',
    ],
    'max_digits' => 'Kolom :attribute tidak boleh lebih dari :max digit.',
    'mimes' => 'Kolom :attribute wajib berupa file dengan tipe: :values.',
    'mimetypes' => 'Kolom :attribute wajib berupa file dengan tipe: :values.',
    'min' => [
        'array' => 'Kolom :attribute wajib memiliki minimal :min item.',
        'file' => 'Kolom :attribute wajib minimal :min kilobyte.',
        'numeric' => 'Kolom :attribute wajib minimal :min.',
        'string' => 'Kolom :attribute wajib minimal :min karakter.',
    ],
    'min_digits' => 'Kolom :attribute wajib minimal :min digit.',
    'missing' => 'Kolom :attribute wajib tidak ada.',
    'missing_if' => 'Kolom :attribute wajib tidak ada apabila :other adalah :value.',
    'missing_unless' => 'Kolom :attribute wajib tidak ada kecuali :other adalah :value.',
    'missing_with' => 'Kolom :attribute wajib tidak ada apabila :values ada.',
    'missing_with_all' => 'Kolom :attribute wajib tidak ada apabila :values ada.',
    'multiple_of' => 'Kolom :attribute wajib kelipatan dari :value.',
    'not_in' => ':attribute yang dipilih tidak valid.',
    'not_regex' => 'Format kolom :attribute tidak valid.',
    'numeric' => 'Kolom :attribute wajib berupa angka.',
    'password' => [
        'letters' => 'Kolom :attribute wajib mengandung setidaknya satu huruf.',
        'mixed' => 'Kolom :attribute wajib mengandung setidaknya satu huruf besar dan satu huruf kecil.',
        'numbers' => 'Kolom :attribute wajib mengandung setidaknya satu angka.',
        'symbols' => 'Kolom :attribute wajib mengandung setidaknya satu simbol.',
        'uncompromised' => ':attribute yang dimasukkan pernah muncul dalam kebocoran data. Silakan gunakan :attribute lain.',
    ],
    'present' => 'Kolom :attribute wajib ada.',
    'present_if' => 'Kolom :attribute wajib ada apabila :other adalah :value.',
    'present_unless' => 'Kolom :attribute wajib ada kecuali :other adalah :value.',
    'present_with' => 'Kolom :attribute wajib ada apabila :values ada.',
    'present_with_all' => 'Kolom :attribute wajib ada apabila :values ada.',
    'prohibited' => 'Kolom :attribute dilarang diisi.',
    'prohibited_if' => 'Kolom :attribute dilarang diisi apabila :other adalah :value.',
    'prohibited_if_accepted' => 'Kolom :attribute dilarang diisi apabila :other disetujui.',
    'prohibited_if_declined' => 'Kolom :attribute dilarang diisi apabila :other ditolak.',
    'prohibited_unless' => 'Kolom :attribute dilarang diisi kecuali :other ada di :values.',
    'prohibits' => 'Kolom :attribute melarang :other untuk diisi.',
    'regex' => 'Format kolom :attribute tidak valid.',
    'required' => 'Kolom :attribute wajib diisi.',
    'required_array_keys' => 'Kolom :attribute wajib berisi entri untuk: :values.',
    'required_if' => 'Kolom :attribute wajib diisi apabila :other adalah :value.',
    'required_if_accepted' => 'Kolom :attribute wajib diisi apabila :other disetujui.',
    'required_if_declined' => 'Kolom :attribute wajib diisi apabila :other ditolak.',
    'required_unless' => 'Kolom :attribute wajib diisi kecuali :other ada di :values.',
    'required_with' => 'Kolom :attribute wajib diisi apabila :values ada.',
    'required_with_all' => 'Kolom :attribute wajib diisi apabila :values ada.',
    'required_without' => 'Kolom :attribute wajib diisi apabila :values tidak ada.',
    'required_without_all' => 'Kolom :attribute wajib diisi apabila tidak satu pun dari :values ada.',
    'same' => 'Kolom :attribute wajib sama dengan :other.',
    'size' => [
        'array' => 'Kolom :attribute wajib berisi :size item.',
        'file' => 'Kolom :attribute wajib berukuran :size kilobyte.',
        'numeric' => 'Kolom :attribute wajib :size.',
        'string' => 'Kolom :attribute wajib :size karakter.',
    ],
    'starts_with' => 'Kolom :attribute wajib diawali dengan salah satu dari: :values.',
    'string' => 'Kolom :attribute wajib berupa teks.',
    'timezone' => 'Kolom :attribute wajib berupa zona waktu yang valid.',
    'unique' => ':attribute sudah digunakan.',
    'uploaded' => ':attribute gagal diunggah.',
    'uppercase' => 'Kolom :attribute wajib huruf besar.',
    'url' => 'Kolom :attribute wajib berupa URL yang valid.',
    'ulid' => 'Kolom :attribute wajib berupa ULID yang valid.',
    'uuid' => 'Kolom :attribute wajib berupa UUID yang valid.',

    /*
    |--------------------------------------------------------------------------
    | Custom Validation Language Lines
    |--------------------------------------------------------------------------
    */

    'custom' => [],

    /*
    |--------------------------------------------------------------------------
    | Custom Validation Attributes
    |--------------------------------------------------------------------------
    |
    | Nama kolom yang dipakai di seluruh endpoint API (auth, mitra, patient,
    | admin) supaya pesan error terbaca alami, mis. "Nomor HP wajib diisi."
    | bukan "phone wajib diisi."
    |
    */

    'attributes' => [
        'name' => 'nama',
        'email' => 'email',
        'phone' => 'nomor HP',
        'password' => 'password',
        'password_confirmation' => 'konfirmasi password',
        'profession' => 'profesi',
        'specialization' => 'spesialisasi',
        'license_number' => 'nomor STR/SIP',
        'work_location' => 'lokasi kerja',
        'latitude' => 'latitude',
        'longitude' => 'longitude',
        'years_of_experience' => 'pengalaman kerja',
        'consultation_fee' => 'tarif konsultasi',
        'bio' => 'bio',
        'str_photo' => 'foto STR',
        'ktp_photo' => 'foto KTP',
        'is_available' => 'status tersedia',
        'status' => 'status',
        'reason' => 'alasan',
        'notes' => 'catatan',
        'address' => 'alamat',
        'service_id' => 'layanan',
        'service_type' => 'jenis layanan',
        'complaint' => 'keluhan',
        'scheduled_at' => 'jadwal',
        'total_amount' => 'total pembayaran',
        'quantity' => 'jumlah',
        'message' => 'pesan',
        'message_type' => 'tipe pesan',
    ],

];

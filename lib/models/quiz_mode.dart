/// Quiz türü: soru nasıl soruluyor.
enum QuizMode {
  /// Örnek cümlede terimin yerinde boşluk var, doğru terim seçilir.
  fillBlank('Fill in the blank', 'Choose the word that completes the sentence'),

  /// İngilizce tanım gösterilir, tanımlanan terim seçilir.
  definition('Find from definition', 'Read the definition and pick the word'),

  /// Terim sesli okunur ama yazılmaz, duyulan terim seçilir.
  listening('Listen and choose', 'Listen to the word and pick what you hear'),

  /// Örnek cümlede boşluk var, şık yok; eksik terim yazılır.
  typing('Type the answer', 'Type the missing word in the sentence'),

  /// Terim gösterilir; kullanıcı söyler, ses tanıma doğru anlaşılıp
  /// anlaşılmadığını kontrol eder.
  speaking('Say the word', 'Say the word out loud to check your pronunciation');

  const QuizMode(this.title, this.subtitle);

  final String title;
  final String subtitle;

  /// Bu türün yalnızca örnek cümlesinde terim geçen kelimeleri sorup
  /// soramayacağı.
  bool get needsBlank => this == QuizMode.fillBlank || this == QuizMode.typing;

  /// Şıklardan seçmek yerine cevabın yazıldığı tür mü.
  bool get isTyped => this == QuizMode.typing;

  /// Şıklardan seçmek yerine cevabın sesli söylendiği tür mü.
  bool get isSpoken => this == QuizMode.speaking;

  /// [quizId] quiz'inin bu türdeki skorunun saklandığı anahtar.
  ///
  /// Boşluk doldurma eski kayıtlarla uyumlu kalsın diye [quizId]'yi aynen
  /// kullanır.
  String scoreId(String quizId) =>
      this == QuizMode.fillBlank ? quizId : '$quizId.$name';
}

import React, { useState, useEffect, useMemo, useRef } from "react";
import { motion, AnimatePresence, type Variants } from "motion/react";
import {
  BookOpen,
  Sparkles,
  Smile,
  Volume2,
  ArrowRight,
  Search,
  Award,
  CheckCircle2,
  XCircle,
  MessageCircle,
  User,
  Users,
  Calendar,
  RotateCcw,
  HelpCircle,
  Heart,
  Info,
  ChevronRight,
  Send,
  MessageSquareHeart,
  Binary,
  Compass,
  Utensils,
  BookMarked
} from "lucide-react";

import {
  VOCABULARY_CATEGORIES,
  ACAN_DAY_NAMES,
  QUIZ_QUESTIONS,
  ADINKRA_SYMBOLS,
  VocabularyItem,
  VocabularyCategory,
  AkanDayName,
  QuizQuestion,
  AdinkraSymbol
} from "./data/twiData";

// Audio sound synthesizer using browser Web Audio API to create a beautiful authentic chime/percussion sound
const playChime = (frequency = 440, type: OscillatorType = "sine") => {
  try {
    const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
    if (!AudioContextClass) return;
    const ctx = new AudioContextClass();
    
    // Create oscillator and gain node
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    
    osc.type = type;
    osc.frequency.setValueAtTime(frequency, ctx.currentTime);
    
    // Elegant decay envelope
    gain.gain.setValueAtTime(0.5, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.8);
    
    osc.connect(gain);
    gain.connect(ctx.destination);
    
    osc.start();
    osc.stop(ctx.currentTime + 0.8);
  } catch (e) {
    console.error("Audio playback error:", e);
  }
};

// ==================== AUTHENTIC ADINKRA SVG GLYPHS ====================
// Consistent monochrome line-art interpretations of traditional Adinkra symbols,
// keyed by the `id` field in ADINKRA_SYMBOLS. Rendered in a single ink color
// (via currentColor) so the whole gallery reads as one visual family.
// Symbol meanings sourced from adinkrasymbols.org.
const ADINKRA_GLYPHS: Record<string, React.ReactNode> = {
  gyenyame: (
    <>
      <path d="M34 68 C 16 56, 22 30, 44 32 C 60 33, 58 51, 45 49 C 37 48, 39 39, 47 41"/>
      <path d="M66 32 C 84 44, 78 70, 56 68 C 40 67, 42 49, 55 51 C 63 52, 61 61, 53 59"/>
    </>
  ),
  sankofa: (
    <>
      {/* Sankofa bird: slim, standing, neck arched back, head turned to retrieve the egg on its breast */}
      <ellipse cx="49" cy="62" rx="13" ry="17" fill="currentColor" stroke="none" />
      <path d="M58 54 L78 38 L60 52 Z" fill="currentColor" stroke="none" />
      <path d="M56 50 C 70 40, 68 20, 52 20 C 45 20, 43 27, 47 31" fill="none" stroke="currentColor" strokeWidth={8} />
      <circle cx="50" cy="21" r="5.5" fill="currentColor" stroke="none" />
      <path d="M48 25 L37 32 L49 30 Z" fill="currentColor" stroke="none" />
      <ellipse cx="43" cy="46" rx="5.5" ry="6.5" fill="#f3f7f1" stroke="currentColor" strokeWidth={3} />
      <path d="M46 78 L44 89" />
      <path d="M53 78 L55 89" />
      <path d="M39 89 H48" />
      <path d="M51 89 H60" />
    </>
  ),
  dwennimmen: (
    <>
      <path d="M50 34 V66"/>
      <path d="M50 34 C 34 30, 26 40, 34 48 C 40 53, 48 49, 45 43"/>
      <path d="M50 34 C 66 30, 74 40, 66 48 C 60 53, 52 49, 55 43"/>
      <path d="M50 66 C 34 70, 26 60, 34 52 C 40 47, 48 51, 45 57"/>
      <path d="M50 66 C 66 70, 74 60, 66 52 C 60 47, 52 51, 55 57"/>
    </>
  ),
  akoma: (
    <>
      <path d="M50 78 C 18 54, 26 26, 45 33 C 50 35, 50 43, 50 48 C 50 43, 50 35, 55 33 C 74 26, 82 54, 50 78 Z" fill="currentColor" stroke="none"/>
    </>
  ),
  nkyinkyim: (
    <>
      <path d="M20 68 L36 68 L36 40 L52 40 L52 68 L68 68 L68 40 L80 40"/>
    </>
  ),
  adinkrahene: (
    <>
      <circle cx="50" cy="50" r="32"/>
      <circle cx="50" cy="50" r="20"/>
      <circle cx="50" cy="50" r="8" fill="currentColor" stroke="none"/>
    </>
  ),
  mate_masie: (
    <>
      <path d="M60 24 A 30 30 0 1 0 60 76"/>
      <path d="M57 38 A 15 15 0 1 0 57 62"/>
      <circle cx="53" cy="50" r="5" fill="currentColor" stroke="none"/>
    </>
  ),
  fihankra: (
    <>
      <path d="M64 74 H26 V26 H74 V64 H44 V46"/>
    </>
  ),
  aya: (
    <>
      <path d="M50 84 V20"/>
      <path d="M50 36 C 40 34, 35 27, 35 22"/>
      <path d="M50 36 C 60 34, 65 27, 65 22"/>
      <path d="M50 50 C 39 48, 33 41, 33 35"/>
      <path d="M50 50 C 61 48, 67 41, 67 35"/>
      <path d="M50 64 C 40 62, 35 55, 35 49"/>
      <path d="M50 64 C 60 62, 65 55, 65 49"/>
    </>
  ),
  funtumfunefu: (
    <>
      <path d="M50 50 C 40 38, 36 26, 28 20"/>
      <path d="M50 50 C 60 38, 64 26, 72 20"/>
      <path d="M50 50 C 40 62, 36 74, 28 80"/>
      <path d="M50 50 C 60 62, 64 74, 72 80"/>
      <circle cx="50" cy="50" r="8" fill="currentColor" stroke="none"/>
      <circle cx="28" cy="20" r="3.5" fill="currentColor" stroke="none"/>
      <circle cx="72" cy="20" r="3.5" fill="currentColor" stroke="none"/>
      <circle cx="28" cy="80" r="3.5" fill="currentColor" stroke="none"/>
      <circle cx="72" cy="80" r="3.5" fill="currentColor" stroke="none"/>
    </>
  ),
  nyame_dua: (
    <>
      <path d="M50 50 V24"/>
      <path d="M50 24 L44 32"/>
      <path d="M50 24 L56 32"/>
      <path d="M50 50 V76"/>
      <path d="M50 76 L44 68"/>
      <path d="M50 76 L56 68"/>
      <path d="M50 50 H24"/>
      <path d="M24 50 L32 44"/>
      <path d="M24 50 L32 56"/>
      <path d="M50 50 H76"/>
      <path d="M76 50 L68 44"/>
      <path d="M76 50 L68 56"/>
      <circle cx="50" cy="50" r="6" fill="currentColor" stroke="none"/>
    </>
  ),
  epa: (
    <>
      <circle cx="36" cy="50" r="16"/>
      <circle cx="64" cy="50" r="16"/>
    </>
  ),
  akofena: (
    <>
      <path d="M30 74 L68 28"/>
      <path d="M70 74 L32 28"/>
      <path d="M22 66 L40 78"/>
      <path d="M60 78 L78 66"/>
      <circle cx="29" cy="77" r="4" fill="currentColor" stroke="none"/>
      <circle cx="71" cy="77" r="4" fill="currentColor" stroke="none"/>
    </>
  ),
  akoben: (
    <>
      <path d="M28 34 C 30 22, 48 22, 58 30 C 74 42, 78 64, 70 78 C 70 64, 62 54, 48 52 C 36 50, 30 46, 28 34 Z"/>
      <circle cx="29" cy="32" r="4" fill="currentColor" stroke="none"/>
    </>
  ),
  osram_ne_nsoromma: (
    <>
      <path d="M58 22 C 30 26, 30 74, 58 78 C 44 60, 44 40, 58 22 Z" fill="currentColor" stroke="none"/>
      <path d="M70.0 19.0 L72.6 26.4 L80.5 26.6 L74.3 31.4 L76.5 38.9 L70.0 34.5 L63.5 38.9 L65.7 31.4 L59.5 26.6 L67.4 26.4 Z" fill="currentColor" stroke="none"/>
    </>
  ),
  nkonsonkonson: (
    <>
      <ellipse cx="30" cy="50" rx="14" ry="9"/>
      <ellipse cx="50" cy="50" rx="14" ry="9"/>
      <ellipse cx="70" cy="50" rx="14" ry="9"/>
    </>
  ),
  hye_wo_nhye: (
    <>
      <circle cx="37" cy="50" r="18"/>
      <circle cx="37" cy="50" r="7"/>
      <circle cx="63" cy="50" r="18"/>
      <circle cx="63" cy="50" r="7"/>
    </>
  ),
  mpatapo: (
    <>
      <path d="M40 28 C 22 28, 22 50, 40 50 C 58 50, 58 72, 40 72"/>
      <path d="M60 28 C 78 28, 78 50, 60 50 C 42 50, 42 72, 60 72"/>
    </>
  ),
  owuo_atwedee: (
    <>
      <path d="M37 22 L33 80"/>
      <path d="M63 22 L67 80"/>
      <path d="M35 34 L65 34"/>
      <path d="M35 46 L65 46"/>
      <path d="M35 58 L65 58"/>
      <path d="M34 70 L66 70"/>
    </>
  ),
  aban: (
    <>
      <rect x="22" y="22" width="56" height="56"/>
      <rect x="34" y="34" width="32" height="32"/>
      <rect x="45" y="45" width="10" height="10" fill="currentColor" stroke="none"/>
    </>
  ),
  mframadan: (
    <>
      <rect x="24" y="24" width="52" height="52"/>
      <path d="M41 24 V76"/>
      <path d="M59 24 V76"/>
      <path d="M24 41 H76"/>
      <path d="M24 59 H76"/>
    </>
  ),
  duafe: (
    <>
      <path d="M28 40 H72"/>
      <path d="M50 40 C 50 30, 46 26, 50 22 C 54 26, 50 30, 50 40"/>
      <path d="M32 40 V68"/>
      <path d="M41 40 V72"/>
      <path d="M50 40 V74"/>
      <path d="M59 40 V72"/>
      <path d="M68 40 V68"/>
    </>
  ),
  denkyem: (
    <>
      <path d="M16 56 C 32 50, 48 50, 60 50 L74 44 L82 50 L74 55 L62 56 C 48 60, 30 60, 18 60 Z" fill="currentColor" stroke="none"/>
      <path d="M30 50 L34 42 L40 50"/>
      <path d="M44 50 L48 42 L54 50"/>
      <path d="M30 60 L28 70"/>
      <path d="M52 60 L54 70"/>
    </>
  ),
  akoma_ntoaso: (
    <>
      <path d="M38 64 C 22 52, 26 36, 38 40 C 41 41, 41 46, 41 49 C 41 46, 41 41, 44 40 C 50 38, 52 46, 48 52"/>
      <path d="M62 64 C 78 52, 74 36, 62 40 C 59 41, 59 46, 59 49 C 59 46, 59 41, 56 40 C 50 38, 48 46, 52 52"/>
      <path d="M41 49 C 45 56, 55 56, 59 49"/>
    </>
  ),
  odo_nnyew_fie_kwan: (
    <>
      <path d="M50 74 C 22 54, 28 30, 44 34 C 50 36, 50 44, 50 48 C 50 44, 50 36, 56 34 C 72 30, 78 54, 50 74"/>
      <circle cx="50" cy="50" r="7"/>
    </>
  ),
  nea_onnim: (
    <>
      <circle cx="50" cy="33" r="13"/>
      <circle cx="67" cy="50" r="13"/>
      <circle cx="50" cy="67" r="13"/>
      <circle cx="33" cy="50" r="13"/>
    </>
  ),
  nsoromma: (
    <>
      <path d="M50.0 22.0 L57.1 40.3 L76.6 41.3 L61.4 53.7 L66.5 72.7 L50.0 62.0 L33.5 72.7 L38.6 53.7 L23.4 41.3 L42.9 40.3 Z" fill="currentColor" stroke="none"/>
    </>
  ),
  abe_dua: (
    <>
      <path d="M50 84 V44"/>
      <path d="M50 46 C 38 38, 28 36, 22 38"/>
      <path d="M50 46 C 62 38, 72 36, 78 38"/>
      <path d="M50 44 C 42 30, 38 24, 36 18"/>
      <path d="M50 44 C 58 30, 62 24, 64 18"/>
      <path d="M50 42 C 50 28, 50 22, 50 16"/>
    </>
  ),
  adwo: (
    <>
      <path d="M50 20 L74 50 L50 80 L26 50 Z"/>
      <path d="M50 34 L62 50 L50 66 L38 50 Z"/>
    </>
  ),
  agyin_dawuru: (
    <>
      <path d="M34 64 C 34 38, 66 38, 66 64 Z"/>
      <path d="M30 64 H70"/>
      <path d="M50 38 V30"/>
      <circle cx="50" cy="72" r="4" fill="currentColor" stroke="none"/>
    </>
  ),
  akoko_nan: (
    <>
      <circle cx="50" cy="26" r="6"/>
      <path d="M50 32 V60"/>
      <path d="M50 60 L36 78"/>
      <path d="M50 60 L50 80"/>
      <path d="M50 60 L64 78"/>
    </>
  ),
  ananse_ntentan: (
    <>
      <path d="M50 18 V82"/>
      <path d="M18 50 H82"/>
      <path d="M27 27 L73 73"/>
      <path d="M73 27 L27 73"/>
      <circle cx="50" cy="50" r="12"/>
      <circle cx="50" cy="50" r="24"/>
    </>
  ),
  ani_bere_a_enso_gya: (
    <>
      <path d="M22 50 C 35 34, 65 34, 78 50 C 65 66, 35 66, 22 50 Z"/>
      <circle cx="50" cy="50" r="9" fill="currentColor" stroke="none"/>
    </>
  ),
  asase_ye_duru: (
    <>
      <ellipse cx="50" cy="50" rx="30" ry="22"/>
      <path d="M20 50 H80"/>
      <path d="M50 28 C 40 40, 40 60, 50 72"/>
      <path d="M50 28 C 60 40, 60 60, 50 72"/>
    </>
  ),
  bese_saka: (
    <>
      <ellipse cx="40" cy="40" rx="11" ry="14"/>
      <ellipse cx="60" cy="40" rx="11" ry="14"/>
      <ellipse cx="40" cy="62" rx="11" ry="14"/>
      <ellipse cx="60" cy="62" rx="11" ry="14"/>
    </>
  ),
  bi_nka_bi: (
    <>
      <path d="M48 26 C 26 30, 26 54, 46 52 C 34 52, 30 40, 44 38"/>
      <path d="M52 74 C 74 70, 74 46, 54 48 C 66 48, 70 60, 56 62"/>
    </>
  ),
  dame_dame: (
    <>
      <rect x="26" y="26" width="16" height="16" fill="currentColor" stroke="none"/>
      <rect x="26" y="58" width="16" height="16" fill="currentColor" stroke="none"/>
      <rect x="42" y="42" width="16" height="16" fill="currentColor" stroke="none"/>
      <rect x="58" y="26" width="16" height="16" fill="currentColor" stroke="none"/>
      <rect x="58" y="58" width="16" height="16" fill="currentColor" stroke="none"/>
      <rect x="26" y="26" width="48" height="48"/>
    </>
  ),
  dono_ntoaso: (
    <>
      <path d="M22 32 H46 M22 68 H46 M22 32 L46 68 M46 32 L22 68"/>
      <path d="M54 32 H78 M54 68 H78 M54 32 L78 68 M78 32 L54 68"/>
    </>
  ),
  dono: (
    <>
      <path d="M38 32 H62 M38 68 H62 M38 32 L62 68 M62 32 L38 68"/>
    </>
  ),
  eban: (
    <>
      <rect x="24" y="30" width="52" height="40" rx="4"/>
      <path d="M50 62 C 40 54, 42 44, 50 48 C 58 44, 60 54, 50 62"/>
    </>
  ),
  ese_ne_tekrema: (
    <>
      <path d="M24 42 H76"/>
      <path d="M30 42 V52"/>
      <path d="M40 42 V52"/>
      <path d="M50 42 V52"/>
      <path d="M60 42 V52"/>
      <path d="M70 42 V52"/>
      <path d="M42 58 C 42 72, 58 72, 58 58 Z"/>
    </>
  ),
  fafanto: (
    <>
      <path d="M50 34 V66"/>
      <path d="M50 42 C 30 26, 18 42, 30 50 C 18 58, 30 74, 50 58"/>
      <path d="M50 42 C 70 26, 82 42, 70 50 C 82 58, 70 74, 50 58"/>
      <circle cx="50" cy="34" r="4" fill="currentColor" stroke="none"/>
    </>
  ),
  fofo: (
    <>
      <path d="M50 82 V46"/>
      <path d="M50 46 C 40 40, 36 30, 40 22"/>
      <path d="M50 46 C 60 40, 64 30, 60 22"/>
      <path d="M50 46 C 50 34, 50 26, 50 18"/>
      <circle cx="50" cy="16" r="4" fill="currentColor" stroke="none"/>
      <circle cx="40" cy="20" r="3" fill="currentColor" stroke="none"/>
      <circle cx="60" cy="20" r="3" fill="currentColor" stroke="none"/>
    </>
  ),
  gyawu_atiko: (
    <>
      <path d="M50 50 C 50 30, 34 30, 38 46"/>
      <path d="M50 50 C 70 50, 70 34, 54 38"/>
      <path d="M50 50 C 50 70, 66 70, 62 54"/>
      <path d="M50 50 C 30 50, 30 66, 46 62"/>
    </>
  ),
  hwehwemudua: (
    <>
      <rect x="44" y="20" width="12" height="60"/>
      <path d="M44 32 H56"/>
      <path d="M44 44 H56"/>
      <path d="M44 56 H56"/>
      <path d="M44 68 H56"/>
    </>
  ),
  kramo_bone: (
    <>
      <rect x="22" y="34" width="26" height="32"/>
      <rect x="52" y="34" width="26" height="32" fill="currentColor" stroke="none"/>
    </>
  ),
  kuronti_ne_akwamu: (
    <>
      <path d="M44 24 C 24 24, 24 76, 44 76"/>
      <path d="M56 24 C 76 24, 76 76, 56 76"/>
      <circle cx="50" cy="50" r="5" fill="currentColor" stroke="none"/>
    </>
  ),
  kwatakye_atiko: (
    <>
      <path d="M28 72 V28 H72 V72"/>
      <path d="M40 72 V44 H60 V72"/>
      <path d="M50 44 V30"/>
    </>
  ),
  mako: (
    <>
      <path d="M40 36 C 32 44, 32 64, 44 64 C 54 64, 54 48, 44 40 Z"/>
      <path d="M44 36 V28"/>
      <path d="M60 36 C 52 44, 52 64, 64 64 C 74 64, 74 48, 64 40 Z"/>
      <path d="M64 36 V28"/>
    </>
  ),
  menso_wo_kenten: (
    <>
      <path d="M30 38 H70 L64 74 H36 Z"/>
      <path d="M30 38 C 40 30, 60 30, 70 38"/>
      <path d="M38 50 H62"/>
      <path d="M37 62 H63"/>
    </>
  ),
  mmere_dane: (
    <>
      <path d="M50 50 C 50 38, 64 38, 64 50 C 64 66, 44 66, 44 50 C 44 30, 70 30, 70 50 C 70 72, 38 72, 38 50"/>
    </>
  ),
  mpuannum: (
    <>
      <path d="M50 22 V40"/>
      <path d="M50 60 V78"/>
      <path d="M22 50 H40"/>
      <path d="M60 50 H78"/>
      <circle cx="50" cy="50" r="9"/>
      <circle cx="50" cy="22" r="4" fill="currentColor" stroke="none"/>
      <circle cx="50" cy="78" r="4" fill="currentColor" stroke="none"/>
      <circle cx="22" cy="50" r="4" fill="currentColor" stroke="none"/>
      <circle cx="78" cy="50" r="4" fill="currentColor" stroke="none"/>
    </>
  ),
  nsaa: (
    <>
      <rect x="26" y="26" width="48" height="48"/>
      <path d="M26 50 L50 26 L74 50 L50 74 Z"/>
      <path d="M38 38 L62 62"/>
      <path d="M62 38 L38 62"/>
    </>
  ),
  nteasee: (
    <>
      <ellipse cx="42" cy="50" rx="20" ry="14"/>
      <ellipse cx="58" cy="50" rx="20" ry="14"/>
    </>
  ),
  nyame_biribi_wo_soro: (
    <>
      <path d="M24 64 C 24 40, 76 40, 76 64"/>
      <path d="M50 40 V62"/>
      <circle cx="50" cy="32" r="6" fill="currentColor" stroke="none"/>
    </>
  ),
  nyame_nwu_na_mawu: (
    <>
      <rect x="30" y="30" width="40" height="40"/>
      <rect x="30" y="30" width="40" height="40" transform="rotate(45 50 50)"/>
    </>
  ),
  okuafo_pa: (
    <>
      <path d="M34 24 H46"/>
      <path d="M40 24 V58"/>
      <path d="M40 58 C 40 74, 62 74, 66 58 H72"/>
    </>
  ),
  sepow: (
    <>
      <path d="M50 20 L58 60 L50 72 L42 60 Z" fill="currentColor" stroke="none"/>
      <path d="M40 60 H60"/>
      <path d="M50 72 V82"/>
    </>
  ),
  tamfo_bebre: (
    <>
      <path d="M50 24 L60 34 L50 44 L40 34 Z"/>
      <path d="M50 44 L66 60 L50 76 L34 60 Z"/>
    </>
  ),
  uac_nkanea: (
    <>
      <path d="M50 30 V80"/>
      <path d="M30 30 H70"/>
      <path d="M40 80 H60"/>
      <circle cx="30" cy="30" r="6"/>
      <circle cx="50" cy="30" r="6"/>
      <circle cx="70" cy="30" r="6"/>
    </>
  ),
  wawa_aba: (
    <>
      <ellipse cx="50" cy="50" rx="20" ry="28"/>
      <path d="M50 30 C 40 40, 40 60, 50 70"/>
      <path d="M50 30 C 60 40, 60 60, 50 70"/>
      <circle cx="50" cy="50" r="5" fill="currentColor" stroke="none"/>
    </>
  ),
  woforo_dua_pa: (
    <>
      <path d="M40 82 V26"/>
      <path d="M60 82 V26"/>
      <path d="M40 70 H60"/>
      <path d="M40 58 H60"/>
      <path d="M40 46 H60"/>
      <path d="M40 34 H60"/>
      <path d="M38 26 C 50 16, 50 16, 62 26"/>
    </>
  )
};

function AdinkraGlyph({ id, className }: { id: string; className?: string }) {
  return (
    <svg
      viewBox="0 0 100 100"
      className={className}
      fill="none"
      stroke="currentColor"
      strokeWidth={7}
      strokeLinecap="round"
      strokeLinejoin="round"
      role="img"
      aria-hidden="true"
    >
      {ADINKRA_GLYPHS[id] ?? <circle cx="50" cy="50" r="30" />}
    </svg>
  );
}

// ==================== ANIMATION PRESETS (lively but quick — better UX) ====================
const springPop = { type: "spring", stiffness: 420, damping: 18 } as const;

// Container that reveals its children one-by-one (staggered cascade).
const staggerGrid: Variants = {
  hidden: { opacity: 0 },
  show: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.04 } }
};

// Each grid/list item pops in, and lifts playfully on hover.
const popItem: Variants = {
  hidden: { opacity: 0, y: 22, scale: 0.94 },
  show: { opacity: 1, y: 0, scale: 1, transition: { type: "spring", stiffness: 380, damping: 20 } },
  hover: { y: -6, scale: 1.03, transition: { type: "spring", stiffness: 420, damping: 16 } }
};

// The Adinkra glyph reacts when its card is hovered (driven by the parent's "hover" state).
const glyphHover: Variants = {
  hover: { scale: 1.2, rotate: [0, -10, 10, 0], transition: { duration: 0.5, ease: "easeInOut" } }
};

export default function App() {
  // Current tab state: 'lessons' | 'naming' | 'tutor' | 'quizzes' | 'symbols'
  const [activeTab, setActiveTab] = useState<string>("lessons");

  // Lessons State
  const [selectedCategory, setSelectedCategory] = useState<VocabularyCategory | null>(null);
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [activeWordIndex, setActiveWordIndex] = useState<number | null>(null);

  // Naming Calculator State
  const [birthDate, setBirthDate] = useState<string>("");
  const [gender, setGender] = useState<"male" | "female">("male");
  const [calculatedName, setCalculatedName] = useState<{
    dayName: AkanDayName;
    name: string;
    dayOfWeekString: string;
  } | null>(null);

  // Tutor State
  const [chatInput, setChatInput] = useState<string>("");
  const [chatMessages, setChatMessages] = useState<Array<{ role: "user" | "model"; text: string }>>([
    {
      role: "model",
      text: "Mema wo akye (Good morning) / Aha (Good afternoon)! I am **Sankofa AI**, your personal Twi language and Akan culture tutor. You can ask me to translate English phrases, explain grammar rules, or teach you typical Ghanaian expressions. What would you like to learn today?"
    }
  ]);
  const [isTutorLoading, setIsTutorLoading] = useState<boolean>(false);
  const [tutorError, setTutorError] = useState<string | null>(null);
  const chatEndRef = useRef<HTMLDivElement>(null);

  // Translator Quick State
  const [quickText, setQuickText] = useState<string>("");
  const [translationResult, setTranslationResult] = useState<any | null>(null);
  const [isTranslating, setIsTranslating] = useState<boolean>(false);
  const [translateMode, setTranslateMode] = useState<"en-to-twi" | "twi-to-en">("en-to-twi");

  // Quiz State
  const [currentQuizIndex, setCurrentQuizIndex] = useState<number>(0);
  const [selectedAnswer, setSelectedAnswer] = useState<string | null>(null);
  const [quizScore, setQuizScore] = useState<number>(0);
  const [isQuizFinished, setIsQuizFinished] = useState<boolean>(false);
  const [answeredQuestions, setAnsweredQuestions] = useState<Array<{ questionId: string; selected: string; correct: boolean }>>([]);

  // Auto-greeting based on actual day of the week
  const todayGreeting = useMemo(() => {
    try {
      const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
      const dayIndex = new Date().getDay();
      const currentDayName = days[dayIndex];
      const details = ACAN_DAY_NAMES.find(d => d.dayIndex === dayIndex);
      if (details) {
        return {
          dayName: currentDayName,
          twiDay: details.dayTwi,
          male: details.maleName,
          female: details.femaleName,
          attribute: details.attribute
        };
      }
    } catch (e) {
      // fallback
    }
    return {
      dayName: "Friday",
      twiDay: "Fiada",
      male: "Kofi",
      female: "Afia",
      attribute: "Okyere"
    };
  }, []);

  // Filter vocabulary items by search
  const filteredCategoryItems = useMemo(() => {
    if (!selectedCategory) return [];
    if (!searchQuery.trim()) return selectedCategory.items;
    const query = searchQuery.toLowerCase();
    return selectedCategory.items.filter(
      item =>
        item.twi.toLowerCase().includes(query) ||
        item.english.toLowerCase().includes(query) ||
        (item.phonetic && item.phonetic.toLowerCase().includes(query))
    );
  }, [selectedCategory, searchQuery]);

  // Scroll chat to bottom
  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [chatMessages, isTutorLoading]);

  // Calculate Akan Day Name
  const handleCalculateDayName = (e: React.FormEvent) => {
    e.preventDefault();
    if (!birthDate) return;
    
    playChime(523.25, "sine"); // beautiful high C note chime
    
    const dateObj = new Date(birthDate);
    // Adjusting for timezone offset so date is strictly matching what user typed
    const localDate = new Date(dateObj.getTime() + dateObj.getTimezoneOffset() * 60000);
    const dayIndex = localDate.getDay();
    const dayOfWeekNames = [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday"
    ];
    const dayOfWeekString = dayOfWeekNames[dayIndex];
    
    const dayNameConfig = ACAN_DAY_NAMES.find(d => d.dayIndex === dayIndex);
    if (dayNameConfig) {
      const name = gender === "male" ? dayNameConfig.maleName : dayNameConfig.femaleName;
      setCalculatedName({
        dayName: dayNameConfig,
        name,
        dayOfWeekString
      });
    }
  };

  // Chat with Sankofa AI Tutor
  const handleSendChatMessage = async (e?: React.FormEvent, presetText?: string) => {
    if (e) e.preventDefault();
    const messageToSend = presetText || chatInput;
    if (!messageToSend.trim() || isTutorLoading) return;

    setChatMessages(prev => [...prev, { role: "user", text: messageToSend }]);
    if (!presetText) setChatInput("");
    setIsTutorLoading(true);
    setTutorError(null);

    playChime(329.63, "triangle"); // friendly E-note chime

    try {
      // Map history format to standard gemini text parts format
      const history = chatMessages.map(msg => ({
        role: msg.role,
        parts: [{ text: msg.text }]
      }));

      const res = await fetch("/api/tutor", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: messageToSend, history })
      });

      const data = await res.json();
      if (res.ok && data.reply) {
        setChatMessages(prev => [...prev, { role: "model", text: data.reply }]);
        playChime(392.00, "sine"); // successful G-note chime
      } else {
        throw new Error(data.error || "Failed to receive response from tutor.");
      }
    } catch (err: any) {
      setTutorError(err.message || "Something went wrong. Please try again.");
      playChime(220.00, "sawtooth"); // Error tone
    } finally {
      setIsTutorLoading(false);
    }
  };

  // Perform Custom Translation
  const handleTranslateText = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!quickText.trim() || isTranslating) return;

    setIsTranslating(true);
    setTranslationResult(null);
    playChime(349.23, "sine"); // F-note chime

    try {
      const res = await fetch("/api/translate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text: quickText, mode: translateMode })
      });

      const data = await res.json();
      if (res.ok) {
        setTranslationResult(data);
        playChime(523.25, "sine"); // High-C chime for success
      } else {
        throw new Error(data.error || "Translation failed.");
      }
    } catch (err: any) {
      alert("Translation error: " + err.message);
    } finally {
      setIsTranslating(false);
    }
  };

  // Speak Word phonetics / translations
  const speakText = (text: string) => {
    playChime(659.25, "sine"); // soft audio feedback
    if ("speechSynthesis" in window) {
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.rate = 0.85;
      utterance.pitch = 1.0;
      window.speechSynthesis.speak(utterance);
    }
  };

  // Quiz Handling
  const handleAnswerQuiz = (option: string) => {
    if (selectedAnswer !== null) return; // already answered this question
    setSelectedAnswer(option);
    
    const currentQuestion = QUIZ_QUESTIONS[currentQuizIndex];
    const isCorrect = option === currentQuestion.answer;
    
    if (isCorrect) {
      setQuizScore(prev => prev + 1);
      playChime(523.25, "sine"); // crisp correct chime
    } else {
      playChime(220.00, "triangle"); // incorrect buzzer chime
    }

    setAnsweredQuestions(prev => [
      ...prev,
      {
        questionId: currentQuestion.id,
        selected: option,
        correct: isCorrect
      }
    ]);
  };

  const handleNextQuiz = () => {
    setSelectedAnswer(null);
    if (currentQuizIndex < QUIZ_QUESTIONS.length - 1) {
      setCurrentQuizIndex(prev => prev + 1);
    } else {
      setIsQuizFinished(true);
      playChime(587.33, "sine"); // celebratory tone
    }
  };

  const handleResetQuiz = () => {
    setCurrentQuizIndex(0);
    setSelectedAnswer(null);
    setQuizScore(0);
    setIsQuizFinished(false);
    setAnsweredQuestions([]);
    playChime(392.00, "sine");
  };

  // Map icon strings to components
  const renderCategoryIcon = (iconName: string) => {
    switch (iconName) {
      case "MessageSquareHeart":
        return <MessageSquareHeart className="w-6 h-6 text-emerald-600" />;
      case "Users":
        return <Users className="w-6 h-6 text-amber-500" />;
      case "Heart":
        return <Heart className="w-6 h-6 text-rose-500" />;
      case "Binary":
        return <Binary className="w-6 h-6 text-indigo-500" />;
      case "Utensils":
        return <Utensils className="w-6 h-6 text-orange-500" />;
      default:
        return <BookMarked className="w-6 h-6 text-emerald-600" />;
    }
  };

  return (
    <div className="min-h-screen bg-stone-50 text-stone-900 font-sans flex flex-col antialiased">
      {/* Dynamic Cultural Top Banner */}
      <div className="bg-emerald-950 text-stone-100 py-2.5 px-4 text-xs sm:text-sm shadow-sm flex items-center justify-between border-b border-amber-500/20">
        <div className="max-w-7xl mx-auto w-full flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <span className="bg-amber-500 text-emerald-950 font-bold px-2 py-0.5 rounded text-[10px] uppercase tracking-wider">
              Sankofa Daily
            </span>
            <span className="font-medium text-amber-300">
              Akwaaba! Today is {todayGreeting.dayName} ({todayGreeting.twiDay})
            </span>
          </div>
          <div className="text-stone-300 flex items-center gap-1.5 sm:text-right">
            <span>Akan birth names for today:</span>
            <strong className="text-stone-100">
              {todayGreeting.male} (♂) / {todayGreeting.female} (♀)
            </strong>
            <span className="text-stone-400">({todayGreeting.attribute})</span>
          </div>
        </div>
      </div>

      {/* Main Beautiful Header Navigation */}
      <header className="bg-white border-b border-stone-200 sticky top-0 z-40 shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between">
          {/* Brand Identity */}
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-emerald-700 to-emerald-900 flex items-center justify-center shadow-md shadow-emerald-900/10 border-2 border-amber-400">
              {/* Symbolic styled bird-wing to mimic Sankofa */}
              <span className="text-2xl font-bold text-amber-400 select-none">S</span>
            </div>
            <div>
              <h1 id="app-title" className="text-xl sm:text-2xl font-extrabold tracking-tight text-emerald-950 flex items-center gap-1.5">
                SankofaTwi
              </h1>
              <p className="text-xs text-stone-500 font-medium">Learn Twi & Akan Culture Intuitively</p>
            </div>
          </div>

          {/* Nav Links */}
          <nav className="hidden lg:flex items-center gap-1">
            {[
              { id: "lessons", label: "Lessons", icon: BookOpen },
              { id: "naming", label: "Day Name Calculator", icon: Calendar },
              { id: "tutor", label: "Sankofa AI Tutor", icon: Sparkles },
              { id: "quizzes", label: "Interactive Quizzes", icon: Award },
              { id: "symbols", label: "Adinkra Symbols", icon: Compass }
            ].map(tab => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              return (
                <motion.button
                  key={tab.id}
                  id={`nav-tab-${tab.id}`}
                  onClick={() => {
                    setActiveTab(tab.id);
                    setSelectedCategory(null);
                    playChime(440, "sine");
                  }}
                  whileHover={{ y: -2, scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  transition={springPop}
                  className={`relative flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-semibold ${
                    isActive ? "text-emerald-900" : "text-stone-600 hover:text-emerald-900 hover:bg-stone-50"
                  }`}
                >
                  {isActive && (
                    <motion.span
                      layoutId="navIndicator"
                      className="absolute inset-0 bg-emerald-50 rounded-lg border border-emerald-200/50 shadow-sm"
                      transition={springPop}
                    />
                  )}
                  <Icon className={`relative z-10 w-4 h-4 ${isActive ? "text-emerald-700" : "text-stone-400"}`} />
                  <span className="relative z-10">{tab.label}</span>
                </motion.button>
              );
            })}
          </nav>

          {/* Quick Translation Toggle on Right */}
          <div className="flex items-center gap-2">
            <span className="text-xs text-stone-400 hidden xl:inline">Learn, return, and retrieve.</span>
            <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
          </div>
        </div>

        {/* Mobile Navigation Bar */}
        <div className="lg:hidden bg-stone-50/80 backdrop-blur-md border-t border-stone-200 px-2 py-1.5 flex items-center justify-around">
          {[
            { id: "lessons", label: "Lessons", icon: BookOpen },
            { id: "naming", label: "Day Name", icon: Calendar },
            { id: "tutor", label: "Sankofa AI", icon: Sparkles },
            { id: "quizzes", label: "Quizzes", icon: Award },
            { id: "symbols", label: "Symbols", icon: Compass }
          ].map(tab => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <motion.button
                key={tab.id}
                id={`mobile-nav-${tab.id}`}
                onClick={() => {
                  setActiveTab(tab.id);
                  setSelectedCategory(null);
                  playChime(440, "sine");
                }}
                whileTap={{ scale: 0.88 }}
                className={`relative flex flex-col items-center gap-1 py-1.5 px-3 rounded-lg ${
                  isActive ? "text-emerald-800" : "text-stone-500"
                }`}
              >
                {isActive && (
                  <motion.span
                    layoutId="mobileNavIndicator"
                    className="absolute inset-0 bg-emerald-100/70 rounded-lg"
                    transition={springPop}
                  />
                )}
                <Icon className={`relative z-10 w-5 h-5 ${isActive ? "text-emerald-700" : "text-stone-400"}`} />
                <span className="relative z-10 text-[10px] font-bold tracking-wide uppercase">{tab.label}</span>
              </motion.button>
            );
          })}
        </div>
      </header>

      {/* Main App Container */}
      <main className="flex-grow max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-8 flex flex-col">
        <AnimatePresence mode="wait">
          {/* ==================== TAB 1: LESSONS & VOCABULARY ==================== */}
          {activeTab === "lessons" && (
            <motion.div
              key="lessons"
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -15 }}
              transition={{ duration: 0.25 }}
              className="space-y-8 flex-grow flex flex-col"
            >
              {!selectedCategory ? (
                // Category Selector Overview
                <div className="space-y-6">
                  <div className="max-w-3xl">
                    <h2 className="text-2xl sm:text-3xl font-black text-stone-900 tracking-tight">
                      Explore Interactive Twi Lessons
                    </h2>
                    <p className="text-stone-600 mt-2 text-base">
                      Akan / Twi uses beautiful semantic roots. Tap any of the curated categories below to study the phonetic guides, cultural context, and everyday usage patterns.
                    </p>
                  </div>

                  <motion.div
                    className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
                    variants={staggerGrid}
                    initial="hidden"
                    animate="show"
                  >
                    {VOCABULARY_CATEGORIES.map((category) => (
                      <motion.button
                        key={category.id}
                        id={`category-btn-${category.id}`}
                        variants={popItem}
                        whileHover="hover"
                        whileTap={{ scale: 0.97 }}
                        onClick={() => {
                          setSelectedCategory(category);
                          playChime(493.88, "sine"); // B-note chime
                        }}
                        className="group text-left bg-white rounded-2xl p-6 shadow-sm border border-stone-200/60 hover:shadow-lg hover:border-emerald-300 transition-shadow duration-300 cursor-pointer flex flex-col justify-between h-48 relative overflow-hidden"
                      >
                        {/* Decorative subtle corner circle background */}
                        <div className="absolute -right-6 -bottom-6 w-24 h-24 rounded-full bg-stone-50 group-hover:bg-emerald-50/50 transition-colors duration-300" />
                        
                        <div className="space-y-4 relative z-10">
                          <div className="w-12 h-12 rounded-xl bg-stone-100 flex items-center justify-center group-hover:bg-emerald-100/80 transition-colors duration-300">
                            {renderCategoryIcon(category.icon)}
                          </div>
                          <div>
                            <h3 className="font-extrabold text-stone-900 text-lg group-hover:text-emerald-950 transition-colors">
                              {category.name}
                            </h3>
                            <p className="text-stone-500 text-sm mt-1 line-clamp-2">
                              {category.description}
                            </p>
                          </div>
                        </div>

                        <div className="flex items-center gap-1.5 text-xs font-bold text-emerald-700 mt-4 relative z-10">
                          <span>Start Learning</span>
                          <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
                        </div>
                      </motion.button>
                    ))}
                  </motion.div>

                  {/* Quick Translation Tool (Aesthetic full-width section) */}
                  <div className="bg-gradient-to-br from-stone-900 to-emerald-950 text-stone-100 rounded-3xl p-6 sm:p-8 shadow-lg border border-amber-500/20 mt-8">
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">
                      <div className="space-y-4">
                        <span className="bg-amber-500 text-emerald-950 text-[10px] tracking-widest uppercase font-black px-2.5 py-1 rounded-full">
                          Deep Translation Engine
                        </span>
                        <h3 className="text-xl sm:text-2xl font-black tracking-tight">
                          Need custom translation & grammar breakdowns?
                        </h3>
                        <p className="text-stone-300 text-sm leading-relaxed">
                          Enter any English sentence or Twi phrase. Our AI tutor will translate it perfectly, outline phonetic sounds, and detail a grammatical word-by-word breakdown.
                        </p>
                      </div>

                      <form onSubmit={handleTranslateText} className="space-y-4">
                        <div className="flex bg-white/10 rounded-xl p-1 border border-white/10">
                          <button
                            type="button"
                            onClick={() => {
                              setTranslateMode("en-to-twi");
                              playChime(329.63);
                            }}
                            className={`flex-1 text-center py-2 text-xs font-bold rounded-lg transition-colors ${
                              translateMode === "en-to-twi"
                                ? "bg-amber-500 text-emerald-950"
                                : "text-stone-300 hover:text-white"
                            }`}
                          >
                            English ➔ Twi
                          </button>
                          <button
                            type="button"
                            onClick={() => {
                              setTranslateMode("twi-to-en");
                              playChime(329.63);
                            }}
                            className={`flex-1 text-center py-2 text-xs font-bold rounded-lg transition-colors ${
                              translateMode === "twi-to-en"
                                ? "bg-amber-500 text-emerald-950"
                                : "text-stone-300 hover:text-white"
                            }`}
                          >
                            Twi ➔ English
                          </button>
                        </div>

                        <div className="relative">
                          <input
                            type="text"
                            value={quickText}
                            onChange={(e) => setQuickText(e.target.value)}
                            placeholder={
                              translateMode === "en-to-twi"
                                ? "e.g., Please give me cold water..."
                                : "e.g., Mepaakyew kyere me ase..."
                            }
                            className="w-full bg-white text-stone-900 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500 pr-12"
                          />
                          <button
                            type="submit"
                            disabled={isTranslating}
                            className="absolute right-2 top-2 h-8 w-8 bg-emerald-800 text-white rounded-lg flex items-center justify-center hover:bg-emerald-700 transition-colors disabled:bg-stone-700"
                          >
                            {isTranslating ? (
                              <div className="w-4 h-4 border-2 border-stone-200 border-t-transparent rounded-full animate-spin" />
                            ) : (
                              <ArrowRight className="w-4 h-4" />
                            )}
                          </button>
                        </div>
                      </form>
                    </div>

                    {/* Translation Response Display */}
                    {translationResult && (
                      <motion.div
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="mt-6 pt-6 border-t border-white/10 grid grid-cols-1 md:grid-cols-3 gap-6"
                      >
                        <div className="md:col-span-2 space-y-3">
                          <span className="text-amber-400 font-bold text-xs uppercase tracking-wider block">
                            Translation Result
                          </span>
                          <div className="flex items-start gap-3">
                            <button
                              onClick={() => speakText(translationResult.translation)}
                              className="mt-1 bg-white/10 hover:bg-white/20 p-2 rounded-lg text-amber-300 transition-colors"
                              title="Listen"
                            >
                              <Volume2 className="w-4 h-4" />
                            </button>
                            <div>
                              <p className="text-xl font-bold text-white leading-tight">
                                {translationResult.translation}
                              </p>
                              {translationResult.pronunciation && (
                                <p className="text-stone-300 text-sm italic mt-1 font-mono">
                                  Pronunciation: [{translationResult.pronunciation}]
                                </p>
                              )}
                              {translationResult.literalMeaning && (
                                <p className="text-stone-400 text-xs mt-2">
                                  Literal meaning: &ldquo;{translationResult.literalMeaning}&rdquo;
                                </p>
                              )}
                            </div>
                          </div>
                          {translationResult.explanation && (
                            <div className="bg-stone-800/50 rounded-xl p-4 border border-stone-700/30 text-stone-300 text-xs sm:text-sm">
                              <p>{translationResult.explanation}</p>
                            </div>
                          )}
                        </div>

                        {translationResult.breakdown && translationResult.breakdown.length > 0 && (
                          <div className="space-y-3 bg-stone-900/60 rounded-xl p-4 border border-white/5 h-fit max-h-64 overflow-y-auto">
                            <span className="text-amber-400 font-bold text-xs uppercase tracking-wider block">
                              Grammar Breakdown
                            </span>
                            <div className="space-y-2">
                              {translationResult.breakdown.map((b: any, index: number) => (
                                <div
                                  key={index}
                                  className="flex justify-between items-center py-1.5 border-b border-white/5 last:border-b-0"
                                >
                                  <span className="font-bold text-emerald-400 text-sm">{b.word}</span>
                                  <span className="text-stone-300 text-xs text-right ml-2">{b.meaning}</span>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}
                      </motion.div>
                    )}
                  </div>
                </div>
              ) : (
                // Selected Category Word List / Detail Card Deck
                <div className="space-y-6 flex-grow flex flex-col">
                  {/* Category Header */}
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-stone-200 pb-4">
                    <div className="flex items-center gap-3">
                      <button
                        onClick={() => {
                          setSelectedCategory(null);
                          setSearchQuery("");
                          setActiveWordIndex(null);
                          playChime(392);
                        }}
                        className="p-2 hover:bg-stone-200/70 rounded-lg text-stone-600 transition-colors"
                      >
                        <ChevronRight className="w-5 h-5 rotate-180" />
                      </button>
                      <div>
                        <h2 className="text-xl sm:text-2xl font-extrabold text-stone-900">
                          {selectedCategory.name}
                        </h2>
                        <p className="text-stone-500 text-xs sm:text-sm">{selectedCategory.description}</p>
                      </div>
                    </div>

                    {/* Search filter input */}
                    <div className="relative w-full sm:w-64">
                      <Search className="w-4 h-4 text-stone-400 absolute left-3 top-3" />
                      <input
                        type="text"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        placeholder="Search word or translation..."
                        className="w-full bg-white rounded-lg border border-stone-200 pl-9 pr-4 py-2 text-xs sm:text-sm focus:outline-none focus:ring-1 focus:ring-emerald-500"
                      />
                    </div>
                  </div>

                  {/* Word Grid & Side Info Detail Column */}
                  <div className="grid grid-cols-1 lg:grid-cols-5 gap-6 flex-grow items-start">
                    {/* Left Grid: Words */}
                    <div className="lg:col-span-3 grid grid-cols-1 sm:grid-cols-2 gap-4">
                      {filteredCategoryItems.length > 0 ? (
                        filteredCategoryItems.map((item, index) => {
                          const isActive = activeWordIndex === index;
                          return (
                            <button
                              key={index}
                              id={`word-card-${index}`}
                              onClick={() => {
                                setActiveWordIndex(index);
                                playChime(440 + index * 20, "sine");
                              }}
                              className={`group text-left p-4 rounded-xl shadow-sm border transition-all duration-200 cursor-pointer ${
                                isActive
                                  ? "bg-emerald-50/70 border-emerald-400 ring-1 ring-emerald-400"
                                  : "bg-white border-stone-200 hover:border-emerald-200 hover:bg-stone-50/40"
                              }`}
                            >
                              <div className="flex justify-between items-start gap-2">
                                <span className="font-extrabold text-stone-900 text-lg group-hover:text-emerald-950">
                                  {item.twi}
                                </span>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    speakText(item.english);
                                  }}
                                  className="text-stone-400 hover:text-emerald-700 p-1 rounded-full hover:bg-stone-100 transition-colors"
                                >
                                  <Volume2 className="w-3.5 h-3.5" />
                                </button>
                              </div>
                              <p className="text-stone-600 text-sm font-semibold mt-1">
                                {item.english}
                              </p>
                              {item.phonetic && (
                                <p className="text-stone-400 text-xs font-mono mt-1 italic">
                                  [{item.phonetic}]
                                </p>
                              )}
                            </button>
                          );
                        })
                      ) : (
                        <div className="col-span-full py-12 text-center text-stone-400">
                          No matching vocabulary phrases found. Try searching for other terms.
                        </div>
                      )}
                    </div>

                    {/* Right Column: Active Vocabulary Insight Detail Card */}
                    <div className="lg:col-span-2">
                      <div className="bg-white rounded-2xl p-6 border border-stone-200 shadow-sm sticky top-28 space-y-6">
                        {activeWordIndex !== null && filteredCategoryItems[activeWordIndex] ? (
                          <>
                            <div className="border-b border-stone-100 pb-4 space-y-1">
                              <span className="text-[10px] uppercase font-black tracking-widest text-emerald-700">
                                Vocabulary Deep Dive
                              </span>
                              <h3 className="text-2xl font-black text-stone-900 leading-tight">
                                {filteredCategoryItems[activeWordIndex].twi}
                              </h3>
                              <p className="text-lg font-bold text-stone-600">
                                {filteredCategoryItems[activeWordIndex].english}
                              </p>
                            </div>

                            <div className="space-y-4">
                              <div className="space-y-1">
                                <span className="text-xs font-bold text-stone-400 block uppercase">
                                  Phonetic Pronunciation
                                </span>
                                <div className="flex items-center gap-2">
                                  <span className="font-mono text-stone-800 text-sm bg-stone-100 px-2.5 py-1 rounded-lg">
                                    [{filteredCategoryItems[activeWordIndex].phonetic}]
                                  </span>
                                  <button
                                    onClick={() => speakText(filteredCategoryItems[activeWordIndex].english)}
                                    className="p-1.5 bg-emerald-50 text-emerald-800 rounded-lg hover:bg-emerald-100 transition-colors flex items-center gap-1 text-xs font-bold"
                                  >
                                    <Volume2 className="w-3.5 h-3.5" />
                                    <span>Guide</span>
                                  </button>
                                </div>
                              </div>

                              {filteredCategoryItems[activeWordIndex].usageContext && (
                                <div className="space-y-1">
                                  <span className="text-xs font-bold text-stone-400 block uppercase">
                                    Cultural & Social Context
                                  </span>
                                  <p className="text-stone-600 text-sm leading-relaxed bg-stone-50 p-3.5 rounded-xl border border-stone-100 italic">
                                    &ldquo;{filteredCategoryItems[activeWordIndex].usageContext}&rdquo;
                                  </p>
                                </div>
                              )}
                            </div>

                            {/* Ask AI quick tip */}
                            <button
                              onClick={() => {
                                setActiveTab("tutor");
                                handleSendChatMessage(
                                  undefined,
                                  `Can you explain the usage of the Twi word "${filteredCategoryItems[activeWordIndex].twi}" and provide more sample sentences using it?`
                                );
                              }}
                              className="w-full mt-4 bg-emerald-800 hover:bg-emerald-700 text-white rounded-xl py-3 px-4 font-bold text-xs flex items-center justify-center gap-2 transition-all cursor-pointer shadow-sm"
                            >
                              <Sparkles className="w-3.5 h-3.5 text-amber-400 animate-pulse" />
                              <span>Ask AI Tutor for more details</span>
                            </button>
                          </>
                        ) : (
                          <div className="py-12 text-center text-stone-400 space-y-3">
                            <Info className="w-8 h-8 text-stone-300 mx-auto" />
                            <p className="text-sm font-semibold">Select a vocabulary phrase card</p>
                            <p className="text-xs text-stone-400">
                              Click any card on the left to reveal detailed phonetic spellings, literal translations, and cultural usage context!
                            </p>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </motion.div>
          )}

          {/* ==================== TAB 2: AKAN DAY NAME CALCULATOR ==================== */}
          {activeTab === "naming" && (
            <motion.div
              key="naming"
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -15 }}
              transition={{ duration: 0.25 }}
              className="max-w-4xl mx-auto space-y-8 flex-grow"
            >
              <div className="text-center space-y-2 max-w-2xl mx-auto">
                <span className="bg-amber-100 text-amber-800 text-[10px] tracking-widest uppercase font-black px-3 py-1 rounded-full">
                  Krabea (Destiny) & Naming
                </span>
                <h2 className="text-2xl sm:text-3xl font-black text-stone-900 tracking-tight">
                  Discover Your Akan &ldquo;Soul Name&rdquo;
                </h2>
                <p className="text-stone-600 text-sm sm:text-base">
                  In Akan culture, children are traditionally given a name based on the day of the week they are born. Each day represents a cosmic deity, a unique spiritual attribute (Krabea), and character traits.
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-8 items-stretch">
                {/* Form Column */}
                <div className="bg-white rounded-3xl p-6 sm:p-8 shadow-sm border border-stone-200/80 flex flex-col justify-between">
                  <div className="space-y-6">
                    <h3 className="font-extrabold text-stone-950 text-lg flex items-center gap-2">
                      <Calendar className="w-5 h-5 text-emerald-700" />
                      <span>Enter Your Birth Information</span>
                    </h3>

                    <form onSubmit={handleCalculateDayName} className="space-y-5">
                      <div className="space-y-2">
                        <label className="text-xs font-black text-stone-500 uppercase tracking-wider block">
                          Your Date of Birth
                        </label>
                        <input
                          type="date"
                          required
                          value={birthDate}
                          onChange={(e) => setBirthDate(e.target.value)}
                          className="w-full bg-stone-50 text-stone-900 border border-stone-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                        />
                      </div>

                      <div className="space-y-2">
                        <label className="text-xs font-black text-stone-500 uppercase tracking-wider block">
                          Gender Representation
                        </label>
                        <div className="grid grid-cols-2 gap-4">
                          <button
                            type="button"
                            onClick={() => {
                              setGender("male");
                              playChime(440);
                            }}
                            className={`py-3 text-sm font-bold rounded-xl border transition-all ${
                              gender === "male"
                                ? "bg-emerald-50 text-emerald-950 border-emerald-400 ring-1 ring-emerald-400"
                                : "bg-stone-50 border-stone-200 text-stone-600 hover:bg-stone-100"
                            }`}
                          >
                            Male (♂)
                          </button>
                          <button
                            type="button"
                            onClick={() => {
                              setGender("female");
                              playChime(440);
                            }}
                            className={`py-3 text-sm font-bold rounded-xl border transition-all ${
                              gender === "female"
                                ? "bg-emerald-50 text-emerald-950 border-emerald-400 ring-1 ring-emerald-400"
                                : "bg-stone-50 border-stone-200 text-stone-600 hover:bg-stone-100"
                            }`}
                          >
                            Female (♀)
                          </button>
                        </div>
                      </div>

                      <button
                        type="submit"
                        className="w-full bg-emerald-800 hover:bg-emerald-700 text-white font-extrabold rounded-xl py-3.5 px-4 text-sm tracking-wide transition-all shadow-md cursor-pointer mt-2"
                      >
                        Calculate My Akan Name
                      </button>
                    </form>
                  </div>

                  <div className="mt-8 pt-6 border-t border-stone-100 text-stone-500 text-xs space-y-1">
                    <p className="font-bold flex items-center gap-1">
                      <Info className="w-3.5 h-3.5 text-stone-400" />
                      Did you know?
                    </p>
                    <p>
                      Famous figures like Kwame Nkrumah (Ghana's first president born on Saturday - Kwame) and Kofi Annan (former UN Secretary-General born on Friday - Kofi) derived their names exactly this way!
                    </p>
                  </div>
                </div>

                {/* Result Column */}
                <div className="flex flex-col">
                  {calculatedName ? (
                    <motion.div
                      initial={{ scale: 0.95, opacity: 0 }}
                      animate={{ scale: 1, opacity: 1 }}
                      className="bg-gradient-to-b from-stone-900 to-emerald-950 text-stone-100 rounded-3xl p-6 sm:p-8 shadow-xl border border-amber-500/20 text-center flex flex-col justify-between h-full relative overflow-hidden"
                    >
                      {/* Decorative Gold Rings */}
                      <div className="absolute -right-16 -top-16 w-48 h-48 rounded-full border border-amber-500/10" />
                      <div className="absolute -left-16 -bottom-16 w-48 h-48 rounded-full border border-amber-500/10" />

                      <div className="space-y-6 relative z-10">
                        <span className="bg-amber-500 text-emerald-950 text-[10px] tracking-widest uppercase font-black px-3 py-1 rounded-full">
                          Your Akan Identity
                        </span>

                        <div className="space-y-1">
                          <p className="text-stone-400 text-xs uppercase tracking-widest font-semibold">
                            You were born on a {calculatedName.dayOfWeekString} ({calculatedName.dayName.dayTwi})
                          </p>
                          <h4 className="text-4xl sm:text-5xl font-black text-amber-400 tracking-tight py-2 font-serif">
                            {calculatedName.name}
                          </h4>
                          <p className="text-stone-300 font-mono text-xs">
                            Spiritual Appellation: {calculatedName.dayName.attribute}
                          </p>
                        </div>

                        <div className="bg-white/5 rounded-2xl p-5 border border-white/10 text-left space-y-3">
                          <span className="text-xs font-black text-amber-300 uppercase tracking-widest block">
                            Soul Attributes
                          </span>
                          <p className="text-stone-200 text-sm leading-relaxed">
                            {calculatedName.dayName.meaning}
                          </p>
                        </div>
                      </div>

                      <div className="pt-6 mt-6 border-t border-white/10 relative z-10 flex gap-4">
                        <button
                          onClick={() => {
                            setActiveTab("tutor");
                            handleSendChatMessage(
                              undefined,
                              `My traditional Akan name is "${calculatedName.name}", born on a ${calculatedName.dayOfWeekString}. What are some other cultural attributes, traditional praise appellations, or famous figures related to my name?`
                            );
                          }}
                          className="flex-1 bg-white/10 hover:bg-white/20 text-white rounded-xl py-3 text-xs font-extrabold transition-all cursor-pointer"
                        >
                          Explore Appellation
                        </button>
                        <button
                          onClick={() => {
                            const shareText = `My traditional Akan Day Name is ${calculatedName.name}! I was born on a ${calculatedName.dayOfWeekString} (${calculatedName.dayName.dayTwi}), representing the spirit of "${calculatedName.dayName.attribute}". Discover yours on SankofaTwi!`;
                            navigator.clipboard.writeText(shareText);
                            playChime(659.25);
                            alert("Copied custom card text to clipboard!");
                          }}
                          className="flex-1 bg-amber-500 hover:bg-amber-400 text-emerald-950 rounded-xl py-3 text-xs font-extrabold transition-all cursor-pointer"
                        >
                          Copy Certificate Text
                        </button>
                      </div>
                    </motion.div>
                  ) : (
                    <div className="bg-stone-100 rounded-3xl border border-stone-200 border-dashed h-full flex flex-col items-center justify-center text-center p-8 space-y-4">
                      <div className="w-16 h-16 rounded-full bg-stone-200/60 flex items-center justify-center">
                        <User className="w-8 h-8 text-stone-400" />
                      </div>
                      <div className="max-w-xs space-y-1">
                        <p className="text-stone-700 font-bold">Calculation Awaiting</p>
                        <p className="text-stone-400 text-xs">
                          Input your birthdate and select gender in the calculator, then tap "Calculate" to generate your full Akan identity profile!
                        </p>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </motion.div>
          )}

          {/* ==================== TAB 3: SANKOFA AI TUTOR ==================== */}
          {activeTab === "tutor" && (
            <motion.div
              key="tutor"
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -15 }}
              transition={{ duration: 0.25 }}
              className="grid grid-cols-1 lg:grid-cols-4 gap-6 items-stretch flex-grow"
            >
              {/* Tutor Suggestions Column */}
              <div className="lg:col-span-1 bg-white rounded-2xl p-5 border border-stone-200 shadow-sm flex flex-col justify-between h-fit lg:h-full lg:sticky lg:top-28">
                <div className="space-y-4">
                  <div className="flex items-center gap-2 text-emerald-900 border-b border-stone-100 pb-3">
                    <Sparkles className="w-5 h-5 text-amber-500" />
                    <h3 className="font-extrabold text-sm sm:text-base">Sankofa AI Tutor</h3>
                  </div>
                  <p className="text-stone-500 text-xs leading-relaxed">
                    Sankofa AI is specialized in Asante Twi orthography, vocabulary roots, grammatical analysis, and traditional etiquette guidelines.
                  </p>

                  <div className="space-y-2.5 pt-2">
                    <span className="text-[10px] uppercase font-black tracking-widest text-stone-400 block">
                      Ask me to:
                    </span>
                    {[
                      "How do you say 'Merry Christmas'?",
                      "Explain the grammar of 'Ete sen?'",
                      "Translate 'I am visiting Ghana next week'",
                      "Tell me about the Adinkra symbols"
                    ].map((preset, index) => (
                      <button
                        key={index}
                        id={`tutor-preset-${index}`}
                        onClick={() => handleSendChatMessage(undefined, preset)}
                        className="w-full text-left bg-stone-50 hover:bg-emerald-50 hover:text-emerald-950 p-2.5 rounded-lg text-xs font-semibold text-stone-600 transition-all border border-stone-200/50 cursor-pointer"
                      >
                        &ldquo;{preset}&rdquo;
                      </button>
                    ))}
                  </div>
                </div>

                <div className="mt-6 pt-4 border-t border-stone-100 hidden lg:block text-stone-400 text-[10px] space-y-1">
                  <p className="font-bold text-stone-500">API Gateway Secured</p>
                  <p>All communication with the Gemini model is handled safely server-side without exposing API credentials.</p>
                </div>
              </div>

              {/* Chat Interface Column */}
              <div className="lg:col-span-3 bg-white rounded-3xl border border-stone-200 shadow-sm flex flex-col justify-between h-[600px] relative overflow-hidden">
                {/* Chat Message Window */}
                <div className="flex-grow p-6 overflow-y-auto space-y-4 scroll-smooth">
                  {chatMessages.map((msg, index) => {
                    const isModel = msg.role === "model";
                    return (
                      <div
                        key={index}
                        className={`flex ${isModel ? "justify-start" : "justify-end"}`}
                      >
                        <div
                          className={`max-w-[85%] sm:max-w-[75%] rounded-2xl p-4 text-sm leading-relaxed ${
                            isModel
                              ? "bg-stone-100 text-stone-900 border border-stone-200/50 rounded-tl-none"
                              : "bg-emerald-900 text-stone-50 rounded-tr-none"
                          }`}
                        >
                          {/* Formatting helper to bold phrases with stars */}
                          <div className="space-y-2 whitespace-pre-line">
                            {msg.text.split("**").map((part, i) => (
                              i % 2 === 1 ? <strong key={i} className={isModel ? "text-emerald-950 font-black" : "text-amber-300"}>{part}</strong> : part
                            ))}
                          </div>
                        </div>
                      </div>
                    );
                  })}

                  {isTutorLoading && (
                    <div className="flex justify-start">
                      <div className="bg-stone-100 text-stone-600 rounded-2xl rounded-tl-none p-4 text-xs sm:text-sm flex items-center gap-3 border border-stone-200/50">
                        <div className="flex gap-1">
                          <span className="w-1.5 h-1.5 bg-emerald-700 rounded-full animate-bounce delay-100" />
                          <span className="w-1.5 h-1.5 bg-emerald-700 rounded-full animate-bounce delay-200" />
                          <span className="w-1.5 h-1.5 bg-emerald-700 rounded-full animate-bounce delay-300" />
                        </div>
                        <span className="italic font-medium">Sankofa AI is analyzing grammar...</span>
                      </div>
                    </div>
                  )}

                  {tutorError && (
                    <div className="bg-rose-50 border border-rose-200 rounded-xl p-4 text-xs text-rose-800 flex items-center gap-2">
                      <XCircle className="w-4 h-4 shrink-0" />
                      <span>{tutorError}</span>
                    </div>
                  )}

                  <div ref={chatEndRef} />
                </div>

                {/* Input Tray */}
                <form
                  onSubmit={handleSendChatMessage}
                  className="p-4 border-t border-stone-200/80 bg-stone-50 flex gap-2.5 items-center"
                >
                  <input
                    type="text"
                    value={chatInput}
                    onChange={(e) => setChatInput(e.target.value)}
                    placeholder="Ask Sankofa AI anything about Twi language or Akan culture..."
                    className="flex-grow bg-white text-stone-900 rounded-xl border border-stone-200 px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  />
                  <button
                    type="submit"
                    disabled={isTutorLoading || !chatInput.trim()}
                    className="bg-emerald-900 hover:bg-emerald-800 disabled:bg-stone-300 text-white rounded-xl h-11 px-5 flex items-center justify-center transition-colors cursor-pointer shrink-0"
                  >
                    <Send className="w-4 h-4" />
                  </button>
                </form>
              </div>
            </motion.div>
          )}

          {/* ==================== TAB 4: INTERACTIVE QUIZZES ==================== */}
          {activeTab === "quizzes" && (
            <motion.div
              key="quizzes"
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -15 }}
              transition={{ duration: 0.25 }}
              className="max-w-3xl mx-auto flex-grow flex flex-col justify-center"
            >
              {!isQuizFinished ? (
                // Active Quiz Card
                <div className="bg-white rounded-3xl shadow-sm border border-stone-200/80 p-6 sm:p-8 space-y-6">
                  {/* Quiz Header & Progress */}
                  <div className="space-y-2">
                    <div className="flex justify-between items-center text-xs text-stone-400 font-bold uppercase tracking-wider">
                      <span>Quiz category: {QUIZ_QUESTIONS[currentQuizIndex].category}</span>
                      <span>
                        Question {currentQuizIndex + 1} of {QUIZ_QUESTIONS.length}
                      </span>
                    </div>

                    {/* Progress Bar */}
                    <div className="h-2 bg-stone-100 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-emerald-700 transition-all duration-300"
                        style={{
                          width: `${((currentQuizIndex + (selectedAnswer ? 1 : 0)) / QUIZ_QUESTIONS.length) * 100}%`
                        }}
                      />
                    </div>
                  </div>

                  {/* Question Prompt */}
                  <div className="py-2">
                    <h3 className="text-xl sm:text-2xl font-black text-stone-900 tracking-tight leading-snug">
                      {QUIZ_QUESTIONS[currentQuizIndex].question}
                    </h3>
                  </div>

                  {/* Multiple Choice Options */}
                  <div className="space-y-3">
                    {QUIZ_QUESTIONS[currentQuizIndex].options.map((option, index) => {
                      const isSelected = selectedAnswer === option;
                      const isCorrectAnswer = option === QUIZ_QUESTIONS[currentQuizIndex].answer;
                      let optionStyle = "bg-stone-50 border-stone-200 hover:bg-stone-100 text-stone-800";

                      if (selectedAnswer !== null) {
                        if (isSelected) {
                          optionStyle = isCorrectAnswer
                            ? "bg-emerald-50 border-emerald-400 text-emerald-950 ring-1 ring-emerald-400"
                            : "bg-rose-50 border-rose-400 text-rose-950 ring-1 ring-rose-400";
                        } else if (isCorrectAnswer) {
                          optionStyle = "bg-emerald-50/60 border-emerald-400/50 text-emerald-950";
                        } else {
                          optionStyle = "bg-stone-50 opacity-60 border-stone-200 text-stone-400";
                        }
                      }

                      return (
                        <motion.button
                          key={index}
                          id={`quiz-option-${index}`}
                          onClick={() => handleAnswerQuiz(option)}
                          disabled={selectedAnswer !== null}
                          whileHover={selectedAnswer === null ? { scale: 1.02, x: 5 } : undefined}
                          whileTap={selectedAnswer === null ? { scale: 0.98 } : undefined}
                          transition={springPop}
                          className={`w-full text-left p-4 rounded-xl border font-bold text-sm sm:text-base flex items-center justify-between transition-colors duration-200 ${optionStyle} ${
                            selectedAnswer === null ? "cursor-pointer" : "cursor-default"
                          }`}
                        >
                          <span>{option}</span>
                          {selectedAnswer !== null && (
                            <span>
                              {isCorrectAnswer ? (
                                <CheckCircle2 className="w-5 h-5 text-emerald-700" />
                              ) : isSelected ? (
                                <XCircle className="w-5 h-5 text-rose-700" />
                              ) : null}
                            </span>
                          )}
                        </motion.button>
                      );
                    })}
                  </div>

                  {/* Contextual Explanations & Next Button */}
                  {selectedAnswer !== null && (
                    <motion.div
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="bg-stone-50 rounded-2xl p-5 border border-stone-200/50 space-y-4"
                    >
                      <div className="space-y-1">
                        <span className="text-xs font-black text-stone-400 uppercase tracking-widest block">
                          Grammatical / Cultural Insight
                        </span>
                        <p className="text-stone-700 text-sm leading-relaxed">
                          {QUIZ_QUESTIONS[currentQuizIndex].explanation}
                        </p>
                      </div>

                      <div className="flex justify-end">
                        <button
                          onClick={handleNextQuiz}
                          className="bg-emerald-900 hover:bg-emerald-800 text-white font-extrabold rounded-xl py-3 px-6 text-sm flex items-center gap-1.5 transition-colors cursor-pointer"
                        >
                          <span>
                            {currentQuizIndex === QUIZ_QUESTIONS.length - 1 ? "Finish Quiz" : "Next Question"}
                          </span>
                          <ArrowRight className="w-4 h-4" />
                        </button>
                      </div>
                    </motion.div>
                  )}
                </div>
              ) : (
                // Congratulations / Score Card
                <motion.div
                  initial={{ scale: 0.95, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  className="bg-gradient-to-b from-stone-900 to-emerald-950 text-stone-100 rounded-3xl p-8 sm:p-12 shadow-xl border border-amber-500/20 text-center space-y-8 relative overflow-hidden"
                >
                  <div className="absolute -right-16 -top-16 w-48 h-48 rounded-full border border-amber-500/10 animate-pulse" />
                  <div className="absolute -left-16 -bottom-16 w-48 h-48 rounded-full border border-amber-500/10 animate-pulse" />

                  <div className="space-y-4 relative z-10">
                    <div className="w-16 h-16 rounded-full bg-amber-500/10 border border-amber-500/30 flex items-center justify-center mx-auto mb-4">
                      <Award className="w-8 h-8 text-amber-400" />
                    </div>
                    <span className="text-amber-400 font-bold text-xs uppercase tracking-widest block">
                      Ayekoo! (Well Done!)
                    </span>
                    <h3 className="text-3xl sm:text-4xl font-black tracking-tight leading-none text-white">
                      You Completed the Twi Quiz!
                    </h3>
                  </div>

                  <div className="bg-white/5 rounded-3xl p-6 border border-white/10 max-w-sm mx-auto space-y-2 relative z-10">
                    <p className="text-stone-400 text-xs uppercase tracking-widest font-semibold">
                      Your Final Score
                    </p>
                    <p className="text-5xl font-black text-amber-400">
                      {quizScore} <span className="text-2xl text-stone-300">/ {QUIZ_QUESTIONS.length}</span>
                    </p>
                    <p className="text-stone-300 text-xs pt-2 leading-relaxed">
                      {quizScore === QUIZ_QUESTIONS.length
                        ? "Perfect score! You are officially an honorary Twi orator!"
                        : quizScore >= QUIZ_QUESTIONS.length / 2
                        ? "Great job! Your Akan language roots are forming beautifully."
                        : "Good attempt! Review the flashcards to master basic phrases."}
                    </p>
                  </div>

                  <div className="flex flex-col sm:flex-row gap-4 justify-center max-w-md mx-auto relative z-10 pt-4">
                    <button
                      onClick={handleResetQuiz}
                      className="flex-1 bg-white/10 hover:bg-white/20 text-white rounded-xl py-3.5 text-xs font-extrabold transition-all cursor-pointer flex items-center justify-center gap-1.5"
                    >
                      <RotateCcw className="w-4 h-4" />
                      <span>Retake Quiz</span>
                    </button>
                    <button
                      onClick={() => {
                        setActiveTab("lessons");
                        setSelectedCategory(null);
                        playChime(392);
                      }}
                      className="flex-1 bg-amber-500 hover:bg-amber-400 text-emerald-950 rounded-xl py-3.5 text-xs font-extrabold transition-all cursor-pointer"
                    >
                      Browse Lessons
                    </button>
                  </div>
                </motion.div>
              )}
            </motion.div>
          )}

          {/* ==================== TAB 5: ADINKRA SYMBOLS GALLERY ==================== */}
          {activeTab === "symbols" && (
            <motion.div
              key="symbols"
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -15 }}
              transition={{ duration: 0.25 }}
              className="space-y-8 flex-grow"
            >
              <div className="max-w-2xl">
                <span className="bg-emerald-100 text-emerald-800 text-[10px] tracking-widest uppercase font-black px-3 py-1 rounded-full">
                  Akan Philosophy
                </span>
                <h2 className="text-2xl sm:text-3xl font-black text-stone-900 mt-2 tracking-tight">
                  Aesthetic Wisdom of Adinkra Symbols
                </h2>
                <p className="text-stone-600 mt-2 text-sm sm:text-base">
                  Adinkra symbols represent rich philosophical concepts, ancestral wisdom, and guidelines for living harmoniously in society.
                </p>
              </div>

              <motion.div
                className="grid grid-cols-1 md:grid-cols-2 gap-6"
                variants={staggerGrid}
                initial="hidden"
                animate="show"
              >
                {ADINKRA_SYMBOLS.map((symbol) => (
                  <motion.div
                    key={symbol.id}
                    id={`symbol-card-${symbol.id}`}
                    variants={popItem}
                    whileHover="hover"
                    whileTap={{ scale: 0.99 }}
                    className="bg-white rounded-2xl p-6 border border-stone-200/80 shadow-sm flex flex-col sm:flex-row gap-6 hover:shadow-lg hover:border-emerald-200 transition-shadow duration-300 cursor-default"
                  >
                    {/* Authentic Adinkra symbol rendered as consistent monochrome SVG */}
                    <motion.div
                      variants={glyphHover}
                      className="w-16 h-16 sm:w-20 sm:h-20 rounded-2xl bg-gradient-to-br from-emerald-50 to-amber-50 flex items-center justify-center border border-emerald-100 shadow-inner shrink-0 select-none text-emerald-900"
                      role="img"
                      aria-label={`${symbol.name} Adinkra symbol`}
                    >
                      <AdinkraGlyph id={symbol.id} className="w-10 h-10 sm:w-12 sm:h-12" />
                    </motion.div>

                    <div className="space-y-3 flex-grow">
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="font-extrabold text-stone-950 text-lg leading-tight">
                            {symbol.name}
                          </h3>
                          <span className="text-stone-400 text-xs font-medium italic">
                            &ldquo;{symbol.literalTranslation}&rdquo;
                          </span>
                        </div>
                        <span className="text-emerald-700 font-bold text-xs">
                          Value: {symbol.coreValue}
                        </span>
                      </div>

                      <p className="text-stone-600 text-sm leading-relaxed">
                        {symbol.symbolDescription}
                      </p>

                      {/* Ask AI more on this symbol */}
                      <motion.button
                        onClick={() => {
                          setActiveTab("tutor");
                          handleSendChatMessage(
                            undefined,
                            `Can you provide a deep-dive explanation of the Adinkra symbol "${symbol.name}"? Explain its historical background, full philosophical translation, and its relevance in modern Ghanaian architecture or fashion.`
                          );
                        }}
                        whileHover={{ x: 4 }}
                        whileTap={{ scale: 0.95 }}
                        className="text-xs font-bold text-emerald-800 hover:text-emerald-950 flex items-center gap-1 cursor-pointer pt-1"
                      >
                        <span>Analyze philosophical depth</span>
                        <ChevronRight className="w-3.5 h-3.5" />
                      </motion.button>
                    </div>
                  </motion.div>
                ))}
              </motion.div>

              <p className="text-[11px] text-stone-400 pt-2">
                Symbol meanings adapted from{" "}
                <a
                  href="https://www.adinkrasymbols.org"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline hover:text-emerald-700"
                >
                  adinkrasymbols.org
                </a>
                . Glyphs are stylized line-art interpretations of traditional Adinkra symbols.
              </p>
            </motion.div>
          )}
        </AnimatePresence>
      </main>

      {/* Elegant Footer */}
      <footer className="bg-stone-950 text-stone-400 py-10 border-t border-white/5">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-amber-500 flex items-center justify-center text-emerald-950 font-bold text-sm">
              S
            </div>
            <div>
              <p className="font-extrabold text-white text-sm tracking-tight leading-tight">SankofaTwi</p>
              <p className="text-[10px] text-stone-500 font-semibold mt-0.5">&ldquo;Se wo were fi na wosankofa a, yenkyi&rdquo;</p>
            </div>
          </div>

          <p className="text-xs text-stone-500 text-center md:text-right leading-relaxed max-w-sm">
            Twi language learning suite inspired by the philosophy of Sankofa &mdash; the wisdom that we must look to the past to construct the future. Powered secure server-side.
          </p>
        </div>
      </footer>
    </div>
  );
}

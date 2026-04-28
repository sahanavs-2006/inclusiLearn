# 🌟 InclusiLearn: AI-Powered Inclusive Education

**Google Solution Challenge 2026 Submission**
*Addressing UN Sustainable Development Goals: Goal 4 (Quality Education) & Goal 10 (Reduced Inequalities)*

---

## 🚀 [Download APK (Google Drive)](https://drive.google.com/file/d/1FPhMe6T4G7z2I5WvN_74o9l2wrpaMvFv/view?usp=sharing)

## 📖 Overview
InclusiLearn is a multimodal AI tutoring application built with **Flutter**, **Firebase**, and **Gemini 2.5 Flash**. It is designed to bridge the accessibility gap in education by providing personalized, adaptive tutoring for students with diverse learning needs, including Dyslexia and Visual Impairment.

### 🎯 The Problem
Standard educational materials often fail students with learning disabilities or those in underserved regional areas. Information is often "one size fits all," leaving many students behind.

### ✨ The Solution
InclusiLearn uses Generative AI to "re-wrap" educational content in real-time based on a student's specific profile.
- **Scan & Solve**: Capture photos of textbook problems for instant, step-by-step explanations.
- **Conversational Tutor**: A stateful AI that remembers previous context and answers follow-up questions.
- **Adaptive Modes**: 
    - **Dyslexia Mode**: Short sentences and bolded key terms.
    - **Visually Impaired Mode**: Detailed verbal descriptions of diagrams and math symbols.
    - **Simplified Mode**: Uses analogies and simple language.
- **Multilingual Support**: Tutoring in **English, Hindi, Kannada, and Tamil**.
- **Voice-to-Query**: Hands-free interaction for increased accessibility.

---

## 🛠️ Tech Stack & Google Technologies
This project leverages the best of Google's developer ecosystem:
- **Flutter**: For a beautiful, high-performance cross-platform UI.
- **Firebase AI (Google AI SDK)**: To power the **Gemini 2.5 Flash** and **Flash-Lite** models.
- **Cloud Firestore**: For real-time data persistence and session synchronization.
- **Firebase Storage**: To handle student-uploaded images.
- **Google Fonts (Outfit)**: For premium typography and readability.

---

## 📈 Impact & Teacher Dashboard 2.0
InclusiLearn includes a dedicated **Teacher Dashboard** that uses AI to aggregate anonymous student sessions. 
- **Identify Hurdles**: AI identifies the top 3 concepts the class is struggling with.
- **Measurable Impact**: Tracks student "Helpfulness Ratings" (👍/👎) to provide a Classroom Confidence Score.
- **Data-Driven Teaching**: Provides teachers with actionable tips to address common confusion points.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.3.0)
- A Firebase Project with the Google AI (Gemini) API enabled.

### Installation
1. Clone the repo:
   ```bash
   git clone https://github.com/YOUR_USERNAME/inclusilearn.git
   ```
2. Add your API Key:
   Create a `.env` file in the root directory and add:
   ```env
   GEMINI_API_KEY=your_api_key_here
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

---

## 🤝 UN SDGs Alignment
- **Goal 4 (Quality Education)**: Ensuring inclusive and equitable quality education and promoting lifelong learning opportunities for all.
- **Goal 10 (Reduced Inequalities)**: Reducing inequalities by providing specialized tools for students with disabilities and regional language support.

---

*Built with ❤️ for the 2026 Google Solution Challenge.*

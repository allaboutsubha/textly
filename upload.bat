@echo off
color 0a
cls

:: আপনার গিটহাব ইউজারনেম এখানে একবার সেট করে রাখুন
set github_user=allaboutsubha

:: ইউজার থেকে শুধু রিপোজিটরি নাম চাওয়া
set /p repo_name="Enter GitHub Repository Name: "

:: পুরো লিঙ্কটি তৈরি করা হচ্ছে
set repo_url=https://github.com/%github_user%/%repo_name%.git

echo.
echo Target URL: %repo_url%
echo Starting Git Operations...
echo ---------------------------------------

:: ১. Git Init
git init && echo [OK] git init Success || echo [ERROR] git init Failed
echo.

:: ১.১ .gitignore তৈরি করা (নতুন সংযোজন)
:: এখানে upload.bat এবং update.bat কে ইগনোর লিস্টে রাখা হচ্ছে
(
echo upload.bat
echo update.bat
) > .gitignore
echo [OK] .gitignore created with exclusions.
echo.

:: ২. Git Add (সব ফাইল অ্যাড হবে, কিন্তু .gitignore এ থাকা ফাইলগুলো বাদ যাবে)
git add . && echo [OK] All files added Success || echo [ERROR] git add Failed
echo.

:: ৩. Git Commit
git commit -m "first commit" && echo [OK] git commit Success || echo [ERROR] git commit Failed
echo.

:: ৪. Git Branch
git branch -M main && echo [OK] git branch Success || echo [ERROR] git branch Failed
echo.

:: ৫. Git Remote Add
git remote remove origin >nul 2>&1
git remote add origin %repo_url% && echo [OK] Remote URL Added Success || echo [ERROR] Remote Failed
echo.

:: ৬. Git Push
git push -u origin main && echo [OK] Push to GitHub Success || echo [ERROR] Push Failed
echo.

echo ---------------------------------------
echo All tasks are completed!
echo ---------------------------------------
pause
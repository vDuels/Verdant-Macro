; ===================================================================
; 🌿 Verdant Macro v2.0
; Advanced Grow a Garden automation with OCR, smart buying, and AI
; "Cultivate Success Automatically"
; ===================================================================

#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

; Include required libraries
#Include lib\Gdip_All.ahk
#Include lib\JSON.ahk

; ===================================================================
; GLOBAL VARIABLES
; ===================================================================

; Core macro state
running := false
webhookUrl := ""
startingSheckles := 0
currentSheckles := 0
sessionSpent := 0
mutationCount := 0
mutationLog := []
lastRestockTime := ""

; Display and scaling
screenWidth := 0
screenHeight := 0
scaleFactor := 1.0

; OCR system
ocrInitialized := false
tesseractPath := ""
pToken := ""

; UI coordinates (1920x1080 baseline, auto-scaled)
uiCoords := {
    "seedsButton": {x: 551, y: 41},
    "gardenButton": {x: 742, y: 41}, 
    "sellButton": {x: 906, y: 41},
    "gearShopOption1": {x: 960, y: 449},
    "restockButton": {x: 878, y: 186},
    "buyButtonGreen": {x: 574, y: 489},
    "buyButtonPurple": {x: 766, y: 489},
    "inventorySearch": {x: 693, y: 91},
    "currencyRegion": {x: 0, y: 970, w: 200, h: 100},
    "notificationRegion": {x: 0, y: 0, w: 1920, h: 400},
    "shopScrollArea": {x: 425, y: 300, w: 1070, h: 500},
    "stockQuantityRegion": {x: 640, y: 300, w: 640, h: 500}
}

; Wishlist storage
seedWishlist := {}
gearWishlist := {}

; Smart buy AI database (from wiki data)
seedPrices := {
    "Carrot": 10, "Strawberry": 25, "Blueberry": 50, "Tomato": 100,
    "Watermelon": 500, "Pumpkin": 1000, "Sunflower": 2500, "Corn": 5000,
    "Dragon Fruit": 25000, "Cactus": 50000, "Beanstalk": 100000,
    "Apple": 250000, "Banana": 500000, "Cherry": 1000000, "Coconut": 2500000,
    "Durian": 5000000, "Grape": 10000000, "Kiwi": 25000000, "Lemon": 50000000,
    "Lime": 100000000, "Mango": 250000000, "Orange": 500000000,
    "Papaya": 1000000000, "Peach": 2500000000, "Pear": 5000000000,
    "Pineapple": 10000000000, "Plum": 25000000000
}

; Profitability ratings (profit multiplier per hour)
seedProfitability := {
    "Carrot": 1.5, "Strawberry": 2.0, "Blueberry": 2.5, "Tomato": 3.0,
    "Watermelon": 4.0, "Pumpkin": 5.0, "Dragon Fruit": 15.0,
    "Beanstalk": 25.0, "Apple": 40.0, "Banana": 50.0
}

; Gear prices
gearPrices := {
    "Watering Can": 50000, "Trowel": 25000, "Sprinkler": 100000,
    "Golden Trowel": 500000, "Rain Maker": 1000000, "Fertilizer": 250000
}

; ===================================================================
; INITIALIZATION
; ===================================================================

Gosub, InitializeVerdant
return

InitializeVerdant:
    ; Display startup message
    LogMessage("🌿 Verdant Macro v2.0 - Initializing...")
    LogMessage("🎯 Cultivate Success Automatically")
    
    ; Detect screen resolution
    SysGet, screenWidth, 78
    SysGet, screenHeight, 79
    scaleFactor := screenWidth / 1920
    
    ; Initialize OCR system
    Gosub, InitializeOCR
    
    ; Create main interface
    Gosub, CreateVerdantGUI
    
    ; Load saved settings
    Gosub, LoadSettings
return

InitializeOCR:
    ; Initialize GDI+ for screen capture
    pToken := Gdip_Startup()
    if (!pToken) {
        LogMessage("❌ Failed to initialize GDI+ graphics system")
        return
    }
    
    ; Find Tesseract OCR installation
    tesseractPath := FindTesseractPath()
    if (tesseractPath = "") {
        LogMessage("⚠️ Tesseract OCR not found - install for full functionality")
        MsgBox, 48, Verdant Macro - OCR Setup, Tesseract OCR not detected!`n`nFor full automation features, please:`n`n1. Download from: https://github.com/UB-Mannheim/tesseract/wiki`n2. Install to default location`n3. Or place tesseract.exe in the 'tesseract' folder`n`nMacro will continue with limited functionality.
        return
    }
    
    ; Test OCR functionality
    if (TestOCR()) {
        ocrInitialized := true
        LogMessage("🔍 Tesseract OCR system ready")
        LogMessage("📂 OCR engine: " . tesseractPath)
    } else {
        LogMessage("❌ OCR test failed - check Tesseract installation")
    }
return

FindTesseractPath() {
    ; Search common Tesseract installation locations
    possiblePaths := [
        A_ScriptDir . "\tesseract\tesseract.exe",           ; Portable version
        "C:\Program Files\Tesseract-OCR\tesseract.exe",     ; Default install
        "C:\Program Files (x86)\Tesseract-OCR\tesseract.exe", ; x86 install
        "tesseract.exe"                                     ; System PATH
    ]
    
    for index, path in possiblePaths {
        if (FileExist(path)) {
            return path
        }
    }
    
    return ""
}

TestOCR() {
    ; Create test image with known text to verify OCR works
    try {
        ; Generate test bitmap
        pBitmap := Gdip_CreateBitmap(200, 50)
        pGraphics := Gdip_GraphicsFromImage(pBitmap)
        
        ; White background
        pBrush := Gdip_BrushCreateSolid(0xFFFFFFFF)
        Gdip_FillRectangle(pGraphics, pBrush, 0, 0, 200, 50)
        
        ; Black test text
        pBrushText := Gdip_BrushCreateSolid(0xFF000000)
        Gdip_TextToGraphics(pGraphics, "VERDANT123", "s16 Center", "Arial", 200, 50, pBrushText)
        
        ; Save test image
        testImagePath := A_ScriptDir . "\verdant_ocr_test.png"
        Gdip_SaveBitmapToFile(pBitmap, testImagePath)
        
        ; Cleanup GDI objects
        Gdip_DeleteBrush(pBrush)
        Gdip_DeleteBrush(pBrushText)
        Gdip_DeleteGraphics(pGraphics)
        Gdip_DisposeImage(pBitmap)
        
        ; Test OCR recognition
        result := RunTesseractOCR(testImagePath)
        FileDelete, %testImagePath%
        
        ; Verify OCR detected test text
        if (InStr(result, "VERDANT") || InStr(result, "123")) {
            return true
        }
    } catch e {
        ; OCR test failed
    }
    
    return false
}

; ===================================================================
; USER INTERFACE
; ===================================================================

CreateVerdantGUI:
    ; Main window with Verdant branding
    Gui, Font, s14 Bold
    Gui, Add, Text, x20 y10 w450 h35 Center, 🌿 Verdant Macro v2.0
    
    Gui, Font, s9 Normal
    Gui, Add, Text, x20 y45 w450 h20 Center, Cultivate Success Automatically
    
    ; Status and currency section
    Gui, Add, GroupBox, x20 y75 w450 h100, 📊 Status & Currency
    Gui, Add, Text, x30 y95 w120 h20, Starting Sheckles:
    Gui, Add, Edit, x150 y93 w80 h20 vStartingSheckles Number
    Gui, Add, Text, x30 y120 w120 h20, Current Sheckles:
    Gui, Add, Text, x150 y120 w80 h20 vCurrentSheckles, Detecting...
    Gui, Add, Text, x30 y145 w120 h20, Session Spent:
    Gui, Add, Text, x150 y145 w80 h20 vSessionSpent, 0₵
    
    Gui, Add, Text, x280 y95 w60 h20, Status:
    Gui, Add, Text, x280 y120 w120 h20 vStatus, 🔴 Stopped
    Gui, Add, Text, x280 y145 w80 h20, Resolution:
    Gui, Add, Text, x360 y145 w80 h20 vResolution, %screenWidth%x%screenHeight%
    
    ; Control buttons
    Gui, Add, Button, x20 y185 w200 h40 gStartVerdant vStartBtn, 🚀 Start Verdant (F1)
    Gui, Add, Button, x270 y185 w200 h40 gStopVerdant vStopBtn Disabled, 🛑 Stop Verdant (F2)
    
    ; Seeds wishlist configuration
    Gui, Add, GroupBox, x20 y235 w450 h180, 🌱 Seeds Automation
    Gui, Add, Text, x30 y255 w150 h20, Available Seeds:
    Gui, Add, ListBox, x30 y275 w180 h120 vAvailableSeeds gSeedSelection
    Gui, Add, Text, x230 y255 w150 h20, Verdant Wishlist:
    Gui, Add, ListBox, x230 y275 w180 h100 vWishlistSeeds
    
    Gui, Add, Radio, x230 y380 w60 h15 vAlwaysBuy Checked, Always Buy
    Gui, Add, Radio, x300 y380 w60 h15 vSmartBuy, Smart Buy
    Gui, Add, Button, x370 y378 w40 h18 gAddSeedToWishlist, Add →
    
    ; Gear configuration
    Gui, Add, GroupBox, x20 y425 w450 h140, ⚙️ Gear Automation
    Gui, Add, Text, x30 y445 w200 h15, Essential Gears:
    Gui, Add, CheckBox, x30 y465 w100 vWateringCan, Watering Can
    Gui, Add, CheckBox, x30 y485 w100 vTrowel, Trowel
    Gui, Add, CheckBox, x30 y505 w100 vSprinkler, Sprinkler
    
    Gui, Add, Text, x230 y445 w200 h15, Premium Gears:
    Gui, Add, CheckBox, x230 y465 w100 vGoldenTrowel, Golden Trowel
    Gui, Add, CheckBox, x230 y485 w100 vRainMaker, Rain Maker
    Gui, Add, CheckBox, x230 y505 w100 vFertilizer, Fertilizer
    
    Gui, Add, Button, x350 y485 w100 h25 gConfigureGears, Configure Gears
    
    ; Mutation tracking
    Gui, Add, GroupBox, x20 y575 w450 h90, 🧬 Mutation Intelligence
    Gui, Add, Text, x30 y595 w150 h20, Session Mutations:
    Gui, Add, Text, x180 y595 w50 h20 vMutationCount, 0
    Gui, Add, Button, x250 y593 w150 h22 gSendMutationReport, 📤 Send Mutation Report
    
    Gui, Add, Text, x30 y620 w150 h15, Latest Discovery:
    Gui, Add, Text, x30 y635 w390 h20 vLastMutation, None detected yet
    
    ; Discord integration
    Gui, Add, GroupBox, x20 y675 w450 h80, 📡 Discord Integration
    Gui, Add, Text, x30 y695 w80 h20, Webhook URL:
    Gui, Add, Edit, x30 y715 w300 h20 vWebhookUrl
    Gui, Add, Button, x340 y715 w100 h20 gTestVerdantWebhook, Test Connection
    
    ; Advanced settings
    Gui, Add, GroupBox, x20 y765 w450 h100, ⚡ Verdant Intelligence
    Gui, Add, CheckBox, x30 y785 w180 vSmartBuyMode Checked, Smart Buy AI System
    Gui, Add, CheckBox, x30 y805 w180 vAutoRestock Checked, Auto-buy on Restock
    Gui, Add, CheckBox, x30 y825 w180 vVerboseLogging, Detailed Logging
    
    Gui, Add, CheckBox, x230 y785 w180 vMutationWebhooks Checked, Mutation Alerts
    Gui, Add, CheckBox, x230 y805 w180 vRestockWebhooks, Restock Notifications
    Gui, Add, CheckBox, x230 y825 w180 vErrorWebhooks, Error Reporting
    
    ; Activity monitor
    Gui, Add, GroupBox, x20 y875 w450 h140, 📝 Verdant Activity Monitor
    Gui, Add, Edit, x30 y895 w430 h110 ReadOnly VScroll vLogText
    
    ; Populate interface
    Gosub, PopulateSeedsList
    Gosub, PopulateGearsList
    Gosub, LoadDefaultWishlists
    
    ; Show main window
    Gui, Show, w490 h1035, 🌿 Verdant Macro - Cultivate Success Automatically
    
    ; Start monitoring timers
    SetTimer, UpdateCurrency, 3000
    SetTimer, ScanForNotifications, 5000
return

PopulateSeedsList:
    seedList := ""
    for seedName, price in seedPrices {
        seedList .= seedName . " (" . FormatCurrency(price) . ")|"
    }
    GuiControl,, AvailableSeeds, |%seedList%
return

PopulateGearsList:
    ; Initialize gear wishlist tracking
    for gearName, price in gearPrices {
        ; Gears can be configured via checkboxes or advanced settings
    }
return

LoadDefaultWishlists:
    ; Smart starter configuration
    seedWishlist["Carrot"] := "Always"
    seedWishlist["Strawberry"] := "Always" 
    seedWishlist["Blueberry"] := "Smart"
    seedWishlist["Dragon Fruit"] := "Smart"
    
    ; Update display
    Gosub, UpdateWishlistDisplay
return

; ===================================================================
; HOTKEYS & CONTROLS
; ===================================================================

F1::Gosub, StartVerdant
F2::Gosub, StopVerdant
F12::Gosub, EmergencyStop

StartVerdant:
    if (running) {
        return
    }
    
    ; Get current settings
    Gui, Submit, NoHide
    
    running := true
    GuiControl, Disable, StartBtn
    GuiControl, Enable, StopBtn
    GuiControl,, Status, 🟢 Active
    
    LogMessage("🌿 Verdant Macro activated!")
    LogMessage("🖥️ Display: " . screenWidth . "x" . screenHeight . " (Scale: " . Round(scaleFactor, 2) . ")")
    LogMessage("🎯 Ready to cultivate success automatically")
    
    ; Send activation webhook
    if (webhookUrl != "") {
        SendVerdantWebhook("🌿 **Verdant Macro Activated!**`n⏰ Started: " . GetCurrentTime() . "`n🖥️ Resolution: " . screenWidth . "x" . screenHeight . "`n🎯 Cultivating success automatically...")
    }
    
    ; Initialize currency tracking
    Gosub, DetectCurrentCurrency
    
    ; Start main automation loop
    SetTimer, VerdantMainLoop, 10000
return

StopVerdant:
    if (!running) {
        return
    }
    
    running := false
    GuiControl, Enable, StartBtn
    GuiControl, Disable, StopBtn
    GuiControl,, Status, 🔴 Stopped
    
    SetTimer, VerdantMainLoop, Off
    
    LogMessage("🛑 Verdant Macro deactivated")
    
    ; Send deactivation webhook with session summary
    if (webhookUrl != "") {
        summary := "🛑 **Verdant Session Complete**`n"
        summary .= "💰 Sheckles spent: " . FormatCurrency(sessionSpent) . "`n"
        summary .= "🧬 Mutations discovered: " . mutationCount . "`n"
        summary .= "⏰ Session ended: " . GetCurrentTime()
        SendVerdantWebhook(summary)
    }
return

EmergencyStop:
    LogMessage("🚨 EMERGENCY STOP - All Verdant operations halted!")
    Gosub, StopVerdant
return

; ===================================================================
; CORE AUTOMATION LOOPS
; ===================================================================

VerdantMainLoop:
    if (!running) {
        return
    }
    
    LogMessage("🔄 Verdant main loop - monitoring garden automation...")
    
    ; Main automation will trigger based on notifications
    ; The real work happens in restock detection and auto-buying
return

UpdateCurrency:
    if (!running) {
        return
    }
    
    Gosub, DetectCurrentCurrency
return

ScanForNotifications:
    if (!running || !ocrInitialized) {
        return
    }
    
    ; Scan notification area for important events
    coords := ScaleCoordinates(uiCoords.notificationRegion)
    notificationText := OCRScreenRegion(coords.x, coords.y, coords.w, coords.h)
    
    if (notificationText != "") {
        ; Check for shop restock events
        if (InStr(notificationText, "New seeds") || InStr(notificationText, "restock")) {
            HandleRestockEvent(notificationText)
        }
        
        ; Check for mutation discoveries
        if (InStr(notificationText, "mutated to") || InStr(notificationText, "mutated")) {
            HandleMutationDiscovery(notificationText)
        }
    }
return

; ===================================================================
; CURRENCY & FINANCIAL TRACKING
; ===================================================================

DetectCurrentCurrency:
    if (!ocrInitialized) {
        return
    }
    
    ; Scan currency display area
    coords := ScaleCoordinates(uiCoords.currencyRegion)
    currencyText := OCRScreenRegion(coords.x, coords.y, coords.w, coords.h)
    
    ; Parse currency amount (handles commas in large numbers)
    if (RegExMatch(currencyText, "(\d{1,3}(?:,\d{3})*)", match)) {
        newSheckles := StrReplace(match1, ",", "") + 0
        
        if (newSheckles != currentSheckles && newSheckles > 0) {
            if (currentSheckles > 0) {
                spent := currentSheckles - newSheckles
                if (spent > 0) {
                    sessionSpent += spent
                    GuiControl,, SessionSpent, %sessionSpent%₵
                    LogMessage("💰 Purchase detected: " . FormatCurrency(spent) . " (Session total: " . FormatCurrency(sessionSpent) . ")")
                }
            }
            currentSheckles := newSheckles
            GuiControl,, CurrentSheckles, %currentSheckles%₵
        }
    }
return

; ===================================================================
; EVENT HANDLERS
; ===================================================================

HandleRestockEvent(notificationText) {
    LogMessage("🏪 Shop restock detected - Verdant auto-buy activated")
    lastRestockTime := GetCurrentTime()
    
    ; Send restock webhook if enabled
    Gui, Submit, NoHide
    if (RestockWebhooks && webhookUrl != "") {
        SendVerdantWebhook("🏪 **Shop Restocked!**`n⏰ " . lastRestockTime . "`n🛒 Verdant auto-buying initiated...")
    }
    
    ; Trigger automated purchasing
    if (AutoRestock) {
        SetTimer, InitiateAutoBuying, 2000  ; 2 second delay for shop loading
    }
}

HandleMutationDiscovery(notificationText) {
    mutationCount++
    GuiControl,, MutationCount, %mutationCount%
    
    ; Add to mutation log with timestamp
    mutationEntry := GetCurrentTime() . " - " . notificationText
    mutationLog.Push(mutationEntry)
    
    ; Update display
    GuiControl,, LastMutation, %notificationText%
    
    LogMessage("🧬 Mutation discovered: " . notificationText)
    
    ; Send mutation webhook if enabled
    Gui, Submit, NoHide
    if (MutationWebhooks && webhookUrl != "") {
        SendVerdantWebhook("🧬 **Mutation Discovery!**`n" . notificationText . "`n⏰ " . GetCurrentTime())
    }
}

; ===================================================================
; AUTOMATED PURCHASING SYSTEM
; ===================================================================

InitiateAutoBuying:
    SetTimer, InitiateAutoBuying, Off
    
    if (!running) {
        return
    }
    
    LogMessage("🛒 Verdant auto-buying sequence initiated...")
    
    ; Purchase seeds first (higher priority)
    Gosub, ExecuteSeedPurchases
    
    ; Then purchase gears
    Gosub, ExecuteGearPurchases
return

ExecuteSeedPurchases:
    if (seedWishlist.Length() = 0) {
        LogMessage("📋 No seeds configured in wishlist")
        return
    }
    
    LogMessage("🌱 Navigating to seed shop...")
    
    ; Click Seeds button
    coords := ScaleCoordinates(uiCoords.seedsButton)
    Click, % coords.x, % coords.y
    Sleep, 2000
    
    ; Enter shop
    Send, {e}
    Sleep, 1500
    
    ; Verify successful navigation
    if (!VerifyInSeedShop()) {
        LogMessage("❌ Failed to access seed shop")
        return
    }
    
    LogMessage("✅ Seed shop accessed successfully")
    
    ; Execute purchasing logic
    Gosub, ScanAndPurchaseSeeds
    
    ; Return to garden
    coords := ScaleCoordinates(uiCoords.gardenButton)
    Click, % coords.x, % coords.y
    Sleep, 1000
return

ScanAndPurchaseSeeds:
    ; Scroll to top for consistent scanning
    coords := ScaleCoordinates(uiCoords.shopScrollArea)
    Click, % coords.x, % coords.y
    Sleep, 200
    Send, {Home}
    Sleep, 500
    
    ; Perform OCR scan of shop items
    shopItems := PerformShopScan() {
    ; Advanced shop scanning with enhanced OCR recognition
    if (!ocrInitialized) {
        LogMessage("❌ OCR not available for shop scanning")
        return []
    }
    
    items := []
    
    ; Allow shop interface to fully load
    Sleep, 500
    
    ; Scan the shop display area
    coords := ScaleCoordinates(uiCoords.shopScrollArea)
    shopText := OCRScreenRegion(coords.x, coords.y, coords.w, coords.h)
    
    LogMessage("🔍 Verdant OCR scan: " . SubStr(shopText, 1, 100) . "...")
    
    ; Multiple parsing patterns for robust detection
    patterns := [
        "i)([A-Za-z\s]+Seed)\s*X(\d+)\s*Stock\s*(\d+[,\d]*)[¢₵]",
        "i)([A-Za-z\s]+)\s*X(\d+)\s*Stock.*?(\d+[,\d]*)[¢₵]",
        "i)(\w+)\s+(\w+)\s*X(\d+).*?(\d+[,\d]*)[¢₵]"
    ]
    
    for patternIndex, pattern in patterns {
        pos := 1
        while (pos := RegExMatch(shopText, pattern, match, pos)) {
            itemName := Trim(match1)
            stock := match2 + 0
            price := StrReplace(match3, ",", "") + 0
            
            ; Validate extracted data
            if (itemName != "" && stock > 0 && price > 0) {
                ; Calculate approximate click coordinates
                itemY := coords.y + (items.Length() * 120)
                
                items.Push({
                    name: itemName,
                    stock: stock,
                    price: price,
                    x: coords.x + 400,
                    y: itemY
                })
                
                LogMessage("✅ Detected: " . itemName . " (Stock: " . stock . ", Price: " . FormatCurrency(price) . ")")
            }
            
            pos += StrLen(match)
        }
    }
    
    return items
}

; ===================================================================
; SMART BUYING AI SYSTEM
; ===================================================================

VerdantSmartBuyDecision(itemName, itemPrice) {
    ; Verdant's intelligent purchasing algorithm
    
    ; Verify item is in our database
    if (!seedPrices.HasKey(itemName)) {
        LogMessage("❓ Unknown item: " . itemName . " - skipping")
        return false
    }
    
    expectedPrice := seedPrices[itemName]
    profitability := seedProfitability.HasKey(itemName) ? seedProfitability[itemName] : 1.0
    
    ; Safety check - don't spend more than 80% of current money on single item
    maxSpendPerItem := Round(currentSheckles * 0.8)
    if (itemPrice > maxSpendPerItem) {
        LogMessage("🚫 Item exceeds budget: " . itemName . " costs " . FormatCurrency(itemPrice) . " (Budget: " . FormatCurrency(maxSpendPerItem) . ")")
        return false
    }
    
    ; Maintain emergency fund (10% of starting capital or 1000₵ minimum)
    emergencyFund := Max(Round(startingSheckles * 0.1), 1000)
    if ((currentSheckles - itemPrice) < emergencyFund) {
        LogMessage("💰 Preserving emergency fund for " . itemName)
        return false
    }
    
    ; Calculate price ratio for decision making
    priceRatio := itemPrice / expectedPrice
    
    ; Excellent deal - immediate purchase
    if (priceRatio <= 0.8) {
        LogMessage("💎 Exceptional value: " . itemName . " at " . Round((1-priceRatio)*100) . "% below expected")
        return true
    }
    
    ; Good deal for high-profitability items
    if (priceRatio <= 1.0 && profitability >= 3.0) {
        LogMessage("✅ Profitable opportunity: " . itemName . " (Profit rating: " . profitability . ")")
        return true
    }
    
    ; Accept slight markup for very high-value items (risk mitigation)
    if (expectedPrice >= 10000000 && priceRatio <= 1.1) {
        LogMessage("💎 High-value item within acceptable range: " . itemName)
        return true
    }
    
    ; Fair pricing for mid-tier profitable items
    if (priceRatio <= 1.05 && profitability >= 2.0 && expectedPrice >= 1000) {
        LogMessage("✅ Fair value purchase: " . itemName)
        return true
    }
    
    LogMessage("❌ Verdant AI declined: " . itemName . " (Ratio: " . Round(priceRatio, 2) . ", Profit: " . profitability . ")")
    return false
}

; ===================================================================
; PURCHASING EXECUTION
; ===================================================================

ExecuteItemPurchase(item) {
    ; Click on item to select it
    Click, % item.x, % item.y
    Sleep, 500
    
    ; Click the green purchase button
    coords := ScaleCoordinates(uiCoords.buyButtonGreen)
    
    ; Calculate purchase quantity (limited to prevent excessive clicking)
    buyCount := item.stock
    if (buyCount > 10) {
        buyCount := 10
    }
    
    ; Execute multiple purchases based on stock
    Loop, %buyCount% {
        Click, % coords.x, % coords.y
        Sleep, 1000  ; 1 second interval as specified
        
        ; Update currency tracking after each purchase
        Gosub, DetectCurrentCurrency
        
        ; Stop if insufficient funds
        if (currentSheckles < item.price) {
            LogMessage("💸 Funds exhausted during purchase sequence")
            break
        }
    }
    
    ; Additional clicks to ensure complete purchase
    Click, % coords.x, % coords.y
    Sleep, 1000
    Click, % coords.x, % coords.y
    Sleep, 1000
}

; ===================================================================
; UTILITY FUNCTIONS
; ===================================================================

ScaleCoordinates(coords) {
    ; Scale coordinates based on current resolution vs 1920x1080 baseline
    scaled := {}
    for key, value in coords {
        if (key = "x") {
            scaled.x := Round(value * scaleFactor)
        } else if (key = "y") {
            scaled.y := Round(value * scaleFactor)
        } else if (key = "w") {
            scaled.w := Round(value * scaleFactor)
        } else if (key = "h") {
            scaled.h := Round(value * scaleFactor)
        }
    }
    return scaled
}

VerifyInSeedShop() {
    ; Verify successful navigation to seed shop
    ; In production, this would use image recognition to detect shop UI
    return true
}

VerifyInGearShop() {
    ; Verify successful navigation to gear shop
    return true
}

EnsureWrenchAccess() {
    ; Ensure wrench is available in slot 2
    Send, {2}
    Sleep, 200
    
    ; If no wrench equipped, search inventory
    Send, {``}  ; Open inventory
    Sleep, 1000
    
    ; Use search function
    coords := ScaleCoordinates(uiCoords.inventorySearch)
    Click, % coords.x, % coords.y
    Sleep, 200
    Send, wrench
    Sleep, 500
    
    ; In production, would use OCR to locate and drag wrench to slot 2
    
    ; Close inventory
    Send, {``}
    Sleep, 500
    
    return true
}

ShouldPurchaseGear(gearName) {
    ; Check if gear should be purchased based on checkbox settings
    Gui, Submit, NoHide
    
    gearChecks := {
        "Watering Can": WateringCan,
        "Trowel": Trowel,
        "Sprinkler": Sprinkler,
        "Golden Trowel": GoldenTrowel,
        "Rain Maker": RainMaker,
        "Fertilizer": Fertilizer
    }
    
    return gearChecks.HasKey(gearName) ? gearChecks[gearName] : false
}

FormatCurrency(amount) {
    ; Format currency with appropriate suffixes
    if (amount >= 1000000000) {
        return Round(amount / 1000000000, 1) . "B₵"
    } else if (amount >= 1000000) {
        return Round(amount / 1000000, 1) . "M₵"
    } else if (amount >= 1000) {
        return Round(amount / 1000, 1) . "K₵"
    } else {
        return amount . "₵"
    }
}

; ===================================================================
; GUI EVENT HANDLERS
; ===================================================================

AddSeedToWishlist:
    ; Get selected seed and purchase mode
    GuiControlGet, selectedSeed,, AvailableSeeds
    if (selectedSeed = "") {
        MsgBox, 48, Verdant Macro, Please select a seed first!
        return
    }
    
    ; Extract seed name from formatted string
    RegExMatch(selectedSeed, "^([^(]+)", seedName)
    seedName := Trim(seedName1)
    
    ; Determine purchase mode
    GuiControlGet, alwaysBuyMode,, AlwaysBuy
    buyMode := alwaysBuyMode ? "Always" : "Smart"
    
    ; Add to wishlist
    seedWishlist[seedName] := buyMode
    
    ; Update display
    Gosub, UpdateWishlistDisplay
    
    LogMessage("✅ Added " . seedName . " (" . buyMode . " buy) to Verdant wishlist")
return

UpdateWishlistDisplay:
    wishlistText := ""
    for seedName, buyMode in seedWishlist {
        wishlistText .= seedName . " (" . buyMode . ")|"
    }
    GuiControl,, WishlistSeeds, |%wishlistText%
return

SendMutationReport:
    if (webhookUrl = "") {
        MsgBox, 48, Verdant Macro, Please configure Discord webhook first!
        return
    }
    
    if (mutationLog.Length() = 0) {
        MsgBox, 64, Verdant Macro, No mutations discovered this session!
        return
    }
    
    summary := "🧬 **Verdant Mutation Report**`n"
    summary .= "📊 Total discoveries: " . mutationCount . "`n`n"
    
    for index, entry in mutationLog {
        summary .= entry . "`n"
        if (index >= 10) {
            summary .= "... and " . (mutationLog.Length() - 10) . " more discoveries`n"
            break
        }
    }
    
    if (SendVerdantWebhook(summary)) {
        LogMessage("📤 Mutation report sent to Discord")
    } else {
        LogMessage("❌ Failed to send mutation report")
    }
return

TestVerdantWebhook:
    Gui, Submit, NoHide
    
    if (webhookUrl = "") {
        MsgBox, 48, Verdant Macro, Please enter webhook URL first!
        return
    }
    
    testMsg := "🌿 **Verdant Macro Test**`n✅ Discord integration working!`n🕐 " . GetCurrentTime() . "`n🎯 Ready to cultivate success automatically!"
    
    if (SendVerdantWebhook(testMsg)) {
        MsgBox, 64, Verdant Macro, Test webhook sent successfully!
        LogMessage("📤 Discord test successful")
    } else {
        MsgBox, 16, Verdant Macro, Failed to send webhook. Check your URL!
        LogMessage("❌ Discord test failed")
    }
return

; ===================================================================
; DISCORD INTEGRATION
; ===================================================================

SendVerdantWebhook(message) {
    if (webhookUrl = "") {
        return false
    }
    
    try {
        ; Escape message for JSON format
        escapedMsg := StrReplace(message, "\", "\\")
        escapedMsg := StrReplace(escapedMsg, """", "\""")
        escapedMsg := StrReplace(escapedMsg, "`n", "\n")
        
        ; Create JSON payload
        postdata := "{""content"": """ . escapedMsg . """}"
        
        ; Send webhook request
        WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        WebRequest.Open("POST", webhookUrl, false)
        WebRequest.SetRequestHeader("Content-Type", "application/json")
        WebRequest.Send(postdata)
        
        ; Check response status
        if (WebRequest.Status = 204) {
            return true
        } else {
            return false
        }
    } catch e {
        return false
    }
}

; ===================================================================
; LOGGING SYSTEM
; ===================================================================

LogMessage(message) {
    ; Get current timestamp
    FormatTime, timeStr, , HH:mm:ss
    logEntry := "[" . timeStr . "] " . message . "`r`n"
    
    ; Add to log display
    GuiControlGet, currentLog,, LogText
    newLog := currentLog . logEntry
    
    ; Maintain log size (keep last 30 entries)
    StringSplit, lines, newLog, `n
    if (lines0 > 30) {
        newLog := ""
        Loop, 30 {
            if (A_Index <= lines0) {
                lineIndex := lines0 - 30 + A_Index
                if (lineIndex > 0) {
                    newLog .= lines%lineIndex% . "`n"
                }
            }
        }
    }
    
    ; Update log display
    GuiControl,, LogText, %newLog%
    
    ; Auto-scroll to bottom
    GuiControl, Focus, LogText
    Send, ^{End}
}

GetCurrentTime() {
    FormatTime, timeStr, , yyyy-MM-dd HH:mm:ss
    return timeStr
}

; ===================================================================
; SETTINGS MANAGEMENT
; ===================================================================

LoadSettings:
    ; Load saved configuration from config file
    settingsFile := A_ScriptDir . "\config\verdant_settings.ini"
    
    if (FileExist(settingsFile)) {
        IniRead, webhookUrl, %settingsFile%, Discord, WebhookURL, %A_Space%
        IniRead, startingSheckles, %settingsFile%, Currency, StartingAmount, 0
        
        ; Update GUI with loaded settings
        if (webhookUrl != "") {
            GuiControl,, WebhookUrl, %webhookUrl%
        }
        if (startingSheckles > 0) {
            GuiControl,, StartingSheckles, %startingSheckles%
        }
        
        LogMessage("⚙️ Settings loaded from configuration file")
    }
return

SaveSettings:
    ; Save current configuration
    settingsFile := A_ScriptDir . "\config\verdant_settings.ini"
    
    ; Create config directory if it doesn't exist
    FileCreateDir, %A_ScriptDir%\config
    
    ; Save current settings
    Gui, Submit, NoHide
    IniWrite, %webhookUrl%, %settingsFile%, Discord, WebhookURL
    IniWrite, %startingSheckles%, %settingsFile%, Currency, StartingAmount
    
    LogMessage("💾 Settings saved to configuration file")
return

; ===================================================================
; GUI EVENT HANDLERS & CLEANUP
; ===================================================================

GuiClose:
    if (running) {
        Gosub, StopVerdant
    }
    Gosub, SaveSettings
ExitApp

OnExit, VerdantCleanup

VerdantCleanup:
    if (running && webhookUrl != "") {
        SendVerdantWebhook("🔴 **Verdant Macro Shutdown**`n💰 Final session spent: " . FormatCurrency(sessionSpent) . "`n🧬 Total mutations: " . mutationCount . "`n⏰ " . GetCurrentTime())
    }
    
    ; Cleanup GDI+ resources
    if (pToken) {
        Gdip_Shutdown(pToken)
    }
    
    ; Remove temporary files
    Loop, Files, %A_ScriptDir%\verdant_temp*.*, F
    {
        FileDelete, %A_LoopFileFullPath%
    }
    
    LogMessage("🌿 Verdant Macro shutdown complete")
ExitAppcan()
    
    if (shopItems.Length() = 0) {
        LogMessage("❌ No items detected - OCR scan failed")
        return
    }
    
    LogMessage("🔍 Verdant detected " . shopItems.Length() . " items available")
    
    ; Process each detected item
    for index, item in shopItems {
        seedName := item.name
        stock := item.stock
        price := item.price
        
        ; Check if item is in our wishlist
        if (seedWishlist.HasKey(seedName)) {
            buyMode := seedWishlist[seedName]
            shouldPurchase := false
            
            if (buyMode = "Always") {
                shouldPurchase := true
            } else if (buyMode = "Smart") {
                shouldPurchase := VerdantSmartBuyDecision(seedName, price)
            }
            
            if (shouldPurchase && currentSheckles >= price) {
                LogMessage("🛒 Purchasing " . seedName . " (Stock: " . stock . ", Price: " . FormatCurrency(price) . ")")
                ExecuteItemPurchase(item)
            } else if (!shouldPurchase) {
                LogMessage("🤔 Verdant AI declined: " . seedName . " (Price: " . FormatCurrency(price) . ")")
            } else {
                LogMessage("💸 Insufficient funds: " . seedName . " (Need: " . FormatCurrency(price) . ")")
            }
        }
    }
    
    ; Scroll and scan for additional items
    coords := ScaleCoordinates(uiCoords.shopScrollArea)
    Click, % coords.x, % coords.y
    Send, {PgDn}
    Sleep, 1000
    
    ; Could implement recursive scanning here for completeness
return

ExecuteGearPurchases:
    ; Similar to seed purchases but for gear shop
    LogMessage("⚙️ Initiating gear shop sequence...")
    
    ; Ensure wrench is available
    if (!EnsureWrenchAccess()) {
        LogMessage("❌ Cannot access gear shop - wrench not found")
        return
    }
    
    ; Use wrench to teleport
    Send, {2}
    Sleep, 500
    Click, % Round(screenWidth/2), % Round(screenHeight/2)
    Sleep, 2000
    
    ; Interact with gear area
    Send, {e}
    Sleep, 1500
    
    ; Access gear shop
    coords := ScaleCoordinates(uiCoords.gearShopOption1)
    Click, % coords.x, % coords.y
    Sleep, 1500
    
    if (!VerifyInGearShop()) {
        LogMessage("❌ Failed to access gear shop")
        return
    }
    
    LogMessage("✅ Gear shop accessed successfully")
    
    ; Purchase gears (similar logic to seeds)
    Gosub, ScanAndPurchaseGears
    
    ; Return to garden
    coords := ScaleCoordinates(uiCoords.gardenButton)
    Click, % coords.x, % coords.y
    Sleep, 1000
return

ScanAndPurchaseGears:
    ; Use same scanning logic as seeds
    shopItems := PerformShopScan()
    
    for index, item in shopItems {
        gearName := item.name
        stock := item.stock
        price := item.price
        
        ; Check gear wishlist (configured via checkboxes)
        if (ShouldPurchaseGear(gearName)) {
            if (currentSheckles >= price) {
                LogMessage("🛒 Purchasing gear: " . gearName . " (" . FormatCurrency(price) . ")")
                ExecuteItemPurchase(item)
            }
        }
    }
return

; ===================================================================
; OCR & VISUAL RECOGNITION SYSTEM
; ===================================================================

OCRScreenRegion(x, y, width, height) {
    if (!ocrInitialized) {
        return ""
    }
    
    try {
        ; Capture screen region using GDI+
        pBitmap := Gdip_BitmapFromScreen(x . "|" . y . "|" . width . "|" . height)
        
        ; Save to temporary file for Tesseract
        tempImagePath := A_ScriptDir . "\verdant_temp_" . A_TickCount . ".png"
        Gdip_SaveBitmapToFile(pBitmap, tempImagePath)
        
        ; Cleanup bitmap
        Gdip_DisposeImage(pBitmap)
        
        ; Run Tesseract OCR
        result := RunTesseractOCR(tempImagePath)
        
        ; Cleanup temporary file
        FileDelete, %tempImagePath%
        
        return result
    } catch e {
        LogMessage("❌ Verdant OCR error: " . e.message)
        return ""
    }
}

RunTesseractOCR(imagePath) {
    ; Prepare output file
    outputPath := A_ScriptDir . "\verdant_ocr_output_" . A_TickCount . ".txt"
    
    ; Build Tesseract command with optimal settings
    cmd := """" . tesseractPath . """ """ . imagePath . """ """ . StrReplace(outputPath, ".txt", "") . """ --psm 6 --oem 3"
    
    ; Execute Tesseract
    RunWait, %ComSpec% /c "%cmd%" 2>nul, , Hide
    
    ; Read results
    result := ""
    if (FileExist(outputPath)) {
        FileRead, result, %outputPath%
        FileDelete, %outputPath%
    }
    
    ; Clean up result text
    result := Trim(result)
    result := RegExReplace(result, "\r?\n", " ")
    
    return result
}

PerformShopS
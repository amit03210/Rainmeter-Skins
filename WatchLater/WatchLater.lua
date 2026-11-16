function Initialize()
    FilePath = SKIN:MakePathAbsolute("Links.txt")
    Items = {}
    LoadList()
    UpdateUI()
end

function LoadList()
    Items = {}
    local file = io.open(FilePath, "r")
    if not file then return end
    for line in file:lines() do
        local title, url = line:match("^(.-)%s*|%s*(.+)$")
        if title and url then
            table.insert(Items, {title = title, url = url})
        end
    end
    file:close()
end

function SaveList()
    local file = io.open(FilePath, "w")
    if not file then return end
    for _, item in ipairs(Items) do
        file:write(item.title .. " | " .. item.url .. "\n")
    end
    file:close()
end

function UpdateUI()
    for i = 1, 5 do
        local item = Items[i]
        if item then
            SKIN:Bang("!SetOption", "MeterTitle" .. i, "Text", i .. ". " .. item.title)
            SKIN:Bang("!SetOption", "MeterTitle" .. i, "ToolTipText", item.title)
            SKIN:Bang("!SetOption", "MeterDel" .. i, "Text", "--- ")
        else
            SKIN:Bang("!SetOption", "MeterTitle" .. i, "Text", "")
            SKIN:Bang("!SetOption", "MeterTitle" .. i, "ToolTipText", "")
            SKIN:Bang("!SetOption", "MeterDel" .. i, "Text", "")
        end
    end
    SKIN:Bang("!UpdateMeter", "*")
    SKIN:Bang("!Redraw")
end

function OnClipboardRead()
    local clip = SKIN:GetMeasure("MeasureGetClip"):GetStringValue()
    clip = clip:gsub("^%s*(.-)%s*$", "%1")
    if clip:match("^https?://") then
        PendingURL = clip
        SKIN:Bang("!SetVariable", "PendingURL", PendingURL)
        SKIN:Bang("!SetOption", "MeasureWebTitle", "URL", PendingURL)
        SKIN:Bang("!UpdateMeasure", "MeasureWebTitle")
        SKIN:Bang("!CommandMeasure", "MeasureWebTitle", "Update")
    end
end

function OnTitleFetched()
    local rawTitle = SKIN:GetMeasure("MeasureWebTitle"):GetStringValue()
    -- Clean extra whitespace/newlines and common suffixes
    local cleanTitle = rawTitle:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    cleanTitle = cleanTitle:gsub(" %- YouTube$", "")
    if cleanTitle == "" then cleanTitle = PendingURL end
    AddEntry(cleanTitle, PendingURL)
end

function OnTitleFailed()
    -- Fallback to showing the raw URL if the site blocks scraping
    AddEntry(PendingURL, PendingURL)
end

function AddEntry(title, url)
    -- Remove pipe characters from title so it doesn't break the text file format
    title = title:gsub("|", "-")
    table.insert(Items, 1, {title = title, url = url})
    SaveList()
    UpdateUI()
end

function OpenLink(index)
    if Items[index] then
        SKIN:Bang('["' .. Items[index].url .. '"]')
    end
end

function DeleteLink(index)
    if Items[index] then
        table.remove(Items, index)
        SaveList()
        UpdateUI()
    end
end

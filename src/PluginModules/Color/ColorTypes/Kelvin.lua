-- Implementation based on Neil Bartlett's color-temperature
-- https://github.com/neilbartlett/color-temperature

local kelvinBestFit = function(a, b, c, x)
    return a + (b * x) + (c * math.log(x))
end

local kelvinBestFitData = {
    Red = {
        a = 351.97690566805693,
        b = 0.114206453784165,
        c = -40.25366309332127,
    },

    Green1 = {
        a = -155.25485562709179,
        b = -0.44596950469579133,
        c = 104.49216199393888,
    },

    Green2 = {
        a = 325.4494125711974,
        b = 0.07943456536662342,
        c = -28.0852963507957,
    },

    Blue = {
        a = -254.76935184120902,
        b = 0.8274096064007395,
        c = 115.67994401066147
    }
}

---

local Kelvin = {}

Kelvin.toRGB = function(kelvin)
    local temperature = kelvin / 100
    local r255, g255, b255

    if (temperature < 66) then
        -- red
        r255 = 255

        -- green
        local greenData = kelvinBestFitData.Green1

        g255 = temperature - 2
        g255 = math.clamp(kelvinBestFit(greenData.a, greenData.b, greenData.c, g255), 0, 255)
    else
        -- red
        local redData = kelvinBestFitData.Red

        r255 = temperature - 55
        r255 = math.clamp(kelvinBestFit(redData.a, redData.b, redData.c, r255), 0, 255)

        -- green
        local greenData = kelvinBestFitData.Green2

        g255 = temperature - 50
        g255 = math.clamp(kelvinBestFit(greenData.a, greenData.b, greenData.c, g255), 0, 255)
    end

    -- blue
    if (temperature >= 66) then
        b255 = 255
    elseif (temperature <= 20) then
        b255 = 0
    else
        local blueData = kelvinBestFitData.Blue

        b255 = temperature - 10
        b255 = math.clamp(kelvinBestFit(blueData.a, blueData.b, blueData.c, b255), 0, 255)
    end

    return
        math.floor(r255 + 0.5) / 255,
        math.floor(g255 + 0.5) / 255,
        math.floor(b255 + 0.5) / 255
end

Kelvin.fromRGB = function(r, _, b)
    local minTemperature, maxTemperature = 1000, 40000
    local epsilon = 0.4
    
    local temperature, testColor

    while ((maxTemperature - minTemperature) > epsilon) do
        temperature = (minTemperature + maxTemperature) / 2
        testColor = {Kelvin.toRGB(temperature)}

        if ((testColor[3] / testColor[1]) >= (b / r)) then
            maxTemperature = temperature
        else
            minTemperature = temperature
        end
    end

    return math.floor(temperature + 0.5)
end

return Kelvin
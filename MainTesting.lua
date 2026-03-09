--// Base Configuration
local Configuration = {
	UseWorkspace = false, 
	NoActors = false,
	FolderName = "Sigma Spy",
	RepoUrl = [[https://raw.githubusercontent.com/warden-cc/Sigma-Spy/refs/heads/main]],
	ParserUrl = [[http://c1.play2go.cloud:22023/raw/Roblox-parser/dist/Main.luau]],
    Directory = "Sigma Spy"
}

print("1 - Iniciando")

--// Load overwrites
local Parameters = {...}
local Overwrites = Parameters[1]
if typeof(Overwrites) == "table" then
	for Key, Value in Overwrites do
		Configuration[Key] = Value
	end
end

--// Service handler
local Services = setmetatable({}, {
	__index = function(self, Name: string): Instance
		local Service = game:GetService(Name)
		return cloneref(Service)
	end,
})

--// Files module
local Files = loadstring(game:HttpGet(`{Configuration.RepoUrl}/lib/Files.lua`))()
Files:PushConfig(Configuration)
Files:Init({
	Services = Services
})

print("2 - Files cargado")

local Folder = Files.FolderName
local Scripts = {
	--// User configurations
	Config = Files:GetModule(`{Folder}/Config`, "Config"),
	ReturnSpoofs = Files:GetModule(`{Folder}/Return spoofs`, "Return Spoofs"),
	Configuration = Configuration,
	Files = Files,

	--// Libraries
	Process = game:HttpGet(`{Configuration.RepoUrl}/lib/Process.lua`),
	Hook = game:HttpGet(`{Configuration.RepoUrl}/lib/Hook.lua`),
	Flags = game:HttpGet(`{Configuration.RepoUrl}/lib/Flags.lua`),
	Ui = game:HttpGet(`{Configuration.RepoUrl}/lib/Ui.lua`),
	Generation = game:HttpGet(`{Configuration.RepoUrl}/lib/Generation.lua`),
	Communication = game:HttpGet(`{Configuration.RepoUrl}/lib/Communication.lua`)
}

print("3 - Scripts descargados")

--// Services
local Players: Players = Services.Players

--// Dependencies
local Modules = Files:LoadLibraries(Scripts)

print("4 - Librerias cargadas")

local Process = Modules.Process
local Hook = Modules.Hook
local Ui = Modules.Ui
local Generation = Modules.Generation
local Communication = Modules.Communication
local Config = Modules.Config

print("4.1 - Modulos asignados")

local FontContent = Files:GetAsset("ProggyClean.ttf", true)
print("4.2 - Font descargada")

local FontJsonFile = Files:CreateFont("ProggyClean", FontContent)
Ui:SetFontFile(FontJsonFile)
print("4.3 - Font configurada")

Process:CheckConfig(Config)
print("4.4 - Config chequeada")

for Name, Module in next, Modules do
    print("Iniciando: " .. tostring(Name))
    local Init = Module.Init
    if Init then
        Module:Init({
            Modules = Modules,
            Services = Services,
            Configuration = Configuration
        })
        print("Listo: " .. tostring(Name))
    end
end

print("5 - Modulos inicializados")

--// ReGui Create window
local Window = Ui:CreateMainWindow()

print("6 - Ventana creada")

--// Check if Sigma spy is supported
local Supported = Process:CheckIsSupported()
if not Supported then 
	Window:Close()
	return
end

print("7 - Executor soportado")

--// Create communication channel
local ChannelId, Event = Communication:CreateChannel()
Communication:AddCommCallback("QueueLog", function(...)
	Ui:QueueLog(...)
end)
Communication:AddCommCallback("Print", function(...)
	Ui:ConsoleLog(...)
end)

print("8 - Canal de comunicacion creado")

--// Generation swaps
local LocalPlayer = Players.LocalPlayer
Generation:SetSwapsCallback(function(self)
	self:AddSwap(LocalPlayer, {
		String = "LocalPlayer",
	})
	self:AddSwap(LocalPlayer.Character, {
		String = "Character",
		NextParent = LocalPlayer
	})
end)

--// Create window content
Ui:CreateWindowContent(Window)

--// Begin the Log queue 
Ui:SetCommChannel(Event)
Ui:BeginLogService()

print("9 - UI lista")

--// Load hooks
local ActorCode = Files:MakeActorScript(Scripts, ChannelId)
Hook:LoadHooks(ActorCode, ChannelId)

print("10 - Hooks cargados")

task.spawn(function()
	local EnablePatches = Ui:AskUser({
		Title = "Enable function patches?",
		Content = {
			"On some executors, function patches can prevent common detections that executor has",
			"By enabling this, it MAY trigger hook detections in some games, this is why you are asked.",
			"If it doesn't work, rejoin and press 'No'",
			"",
			"(This does not affect game functionality)"
		},
		Options = {"Yes", "No"}
	}) == "Yes"

	print("11 - Usuario respondio el modal")

	--// Begin hooks
	Event:Fire("BeginHooks", {
		PatchFunctions = EnablePatches
	})

	print("12 - BeginHooks disparado")
end)

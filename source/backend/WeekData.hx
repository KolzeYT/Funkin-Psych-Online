package backend;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import tjson.TJSON as Json;

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;
}

class WeekData {
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];
	public var folder:String = '';
	
	// JSON variables
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var freeplayColor:Array<Int>;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var difficulties:String;

	public var fileName:String;

	public static function createWeekFile():WeekFile {
		var weekFile:WeekFile = {
			songs: [["Bopeebo", "dad", [146, 113, 253]], ["Fresh", "dad", [146, 113, 253]], ["Dad Battle", "dad", [146, 113, 253]]],
			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			freeplayColor: [146, 113, 253],
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: ''
		};
		return weekFile;
	}

	// HELP: Is there any way to convert a WeekFile to WeekData without having to put all variables there manually? I'm kind of a noob in haxe lmao
	public function new(weekFile:WeekFile, fileName:String) {
		songs = weekFile.songs;
		weekCharacters = weekFile.weekCharacters;
		weekBackground = weekFile.weekBackground;
		weekBefore = weekFile.weekBefore;
		storyName = weekFile.storyName;
		weekName = weekFile.weekName;
		freeplayColor = weekFile.freeplayColor;
		startUnlocked = weekFile.startUnlocked;
		hiddenUntilUnlocked = weekFile.hiddenUntilUnlocked;
		hideStoryMode = weekFile.hideStoryMode;
		hideFreeplay = weekFile.hideFreeplay;
		difficulties = weekFile.difficulties;

		this.fileName = fileName;
	}

	public static function reloadWeekFiles(?isStoryMode:Null<Bool> /*= false*/)
	{
		if (isStoryMode == null) // dead code btw
			isStoryMode = PlayState.isStoryMode;

		weeksList = [];
		weeksLoaded.clear();
		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods(), Paths.getPreloadPath()];
		var originalLength:Int = directories.length;

		for (mod in Mods.parseList().enabled)
			if(Mods.getModEngine(mod) == ModEngine.PSYCH)
				directories.push(Paths.mods(mod + '/'));
		#else
		var directories:Array<String> = [Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
		#end

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('weeks/weekList.txt'));
		for (i in 0...sexList.length) {
			for (j in 0...directories.length) {
				var fileToCheck:String = directories[j] + 'weeks/' + sexList[i] + '.json';
				if(!weeksLoaded.exists(sexList[i])) {
					var week:WeekFile = getWeekFile(fileToCheck);
					if(week != null) {
						var weekFile:WeekData = new WeekData(week, sexList[i]);

						#if MODS_ALLOWED
						if(j >= originalLength) {
							weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length-1);
						}
						#end

						if (
							weekFile != null && (
								(/*online.GameClient.isConnected() &&*/ !isStoryMode) || //freeplay unlocked patched ad free
								((isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay))
							)
						) {
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i] + 'weeks/';
			if(FileSystem.exists(directory)) {
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');
				for (daWeek in listOfWeeks)
				{
					var path:String = directory + daWeek + '.json';
					if(sys.FileSystem.exists(path))
					{
						addWeek(isStoryMode, daWeek, path, directories[i], i, originalLength);
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						addWeek(isStoryMode, file.substr(0, file.length - 5), path, directories[i], i, originalLength);
					}
				}
			}
		}

		reloadNonPsychWeeks();
		#end
	}

	private static function reloadNonPsychWeeks(){
		var directories:Array<String> = [];

		for (mod in Mods.parseList().enabled)
			if(Mods.getModEngine(mod) != ModEngine.PSYCH)
				directories.push(Paths.mods(mod + '/'));

		var weekFile:WeekData;
		var mod;

		for(dir in directories){
			var songs:Array<String> = [];
			mod = dir.replace("mods/", "").replace("/", "");
			switch(Mods.getModEngine(mod)){
				case ModEngine.VSLICE:
					for (s in FileSystem.readDirectory(dir+"data/songs"))
						songs.push(s);
				default:
					trace('non-compatible mod or no pack.json');
			}
			var weekSongs:Array<Dynamic> = [];
			
			for(s in songs){
				var icon = Json.parse(File.getContent('${dir}data/songs/${s}/${s}-metadata.json')).playData.characters.opponent;
				weekSongs.push([s, icon, [100, 100, 100], true, true]);
			}

			var data:Dynamic = {
				songs: weekSongs,
				weekCharacters: ["dad","bf","gf"],
				weekBackground: "stage",
				storyName: "Daddy Dearest",
				weekBefore: "tutorial",
				weekName: "Week 1",
				hideStoryMode: true,
				startUnloacked: true,
				hideFreeplay: false,
				hiddenUntilUnlocked: false,
				freeplayColor: [100,100,100],
				difficulties: 'easy, normal, hard'
			};

			weekFile = new WeekData(data, mod);
			weekFile.folder = mod;
		
			trace(data, " ", songs, weekFile);
			weeksLoaded.set(mod, weekFile);
			weeksList.push(mod);

		}

	}

	private static function addWeek(isStoryMode:Bool, weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if(!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(path);
			if(week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				if(i >= originalLength)
				{
					#if MODS_ALLOWED
					weekFile.folder = directory.substring(Paths.mods().length, directory.length-1);
					#end
				}
				if(
					(/*online.GameClient.isConnected() &&*/ !isStoryMode) || // freeplay unlocked patched ad free
					((isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay)))
				{
					weeksLoaded.set(weekToCheck, weekFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}

	private static function getWeekFile(path:String):WeekFile {
		var rawJson:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if(OpenFlAssets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end

		if(rawJson != null && rawJson.length > 0) {
			try {
				return cast Json.parse(rawJson);
			}
			catch (exc) {
				trace(exc);
				trace(rawJson);
			}
		}
		return null;
	}

	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE

	//To use on PlayState.hx or Highscore stuff
	public static function getWeekFileName():String {
		return weeksList[PlayState.storyWeek];
	}

	//Used on LoadingState, nothing really too relevant
	public static function getCurrentWeek():WeekData {
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null) {
		Mods.currentModDirectory = '';
		if(data != null && data.folder != null && data.folder.length > 0) {
			Mods.currentModDirectory = data.folder;
		}
		}
}
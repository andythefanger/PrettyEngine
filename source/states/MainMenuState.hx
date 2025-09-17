package states;

import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import lime.app.Application;
import options.OptionsState;
import states.editors.MasterEditorMenu;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

enum MainMenuColumn {
	LEFT;
	CENTER;
	RIGHT;
}

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0.4';
	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = CENTER;

	var allowMouse:Bool = true;
	var menuItems:FlxTypedGroup<FlxSprite>;
	var leftItem:FlxSprite;
	var rightItem:FlxSprite;

	// Only 3 options
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'credits'
	];

	var leftOption:String = null;
	var rightOption:String = 'options';

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	// Background layers
	var checker1:FlxSprite;
	var checker2:FlxSprite;

	var selectedSomethin:Bool = false;

	override function create()
	{
		super.create();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = persistentDraw = true;

		// Main menu background
		var bg = new FlxSprite().loadGraphic(Paths.image("menuDesat"));
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
		bg.updateHitbox();
		add(bg);

		// Infinite checker overlay
		checker1 = new FlxSprite().loadGraphic(Paths.image("checker"));
		checker1.scrollFactor.set(0, 0);
		checker1.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
		checker1.updateHitbox();
		add(checker1);

		checker2 = new FlxSprite(checker1.x, checker1.y - checker1.height).loadGraphic(Paths.image("checker"));
		checker2.scrollFactor.set(0, 0);
		checker2.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
		checker2.updateHitbox();
		add(checker2);

		        var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33005EFF, 0x0));
        grid.velocity.set(40, 40);
        grid.alpha = 0;
        FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
        add(grid);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).makeGraphic(FlxG.width + 160, FlxG.height + 160, 0xFFfd719b);
		magenta.visible = false;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (num => option in optionShit)
		{
			var item:FlxSprite = createMenuItem(option, 0, (num * 140) + 90);
			item.y += (4 - optionShit.length) * 70;
			item.screenCenter(X);
		}

		if (rightOption != null)
		{
			rightItem = createMenuItem(rightOption, FlxG.width - 60, 490);
			rightItem.x -= rightItem.width;
		}

		// Version text
		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);

		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);

		changeItem();
		FlxG.camera.follow(camFollow, null, 0.15);
	}

	function createMenuItem(name:String, x:Float, y:Float):FlxSprite
	{
		var menuItem:FlxSprite = new FlxSprite(x, y);
		menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_$name');
		menuItem.animation.addByPrefix('idle', '$name idle', 24, true);
		menuItem.animation.addByPrefix('selected', '$name selected', 24, true);
		menuItem.animation.play('idle');
		menuItem.updateHitbox();
		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.scrollFactor.set();
		menuItems.add(menuItem);
		return menuItem;
	}

	override function update(elapsed:Float)
	{
		// Scroll checker background
		checker1.y += 30 * elapsed;
		checker2.y += 30 * elapsed;

		if (checker1.y >= FlxG.height) checker1.y = checker2.y - checker1.height;
		if (checker2.y >= FlxG.height) checker2.y = checker1.y - checker2.height;

		// Camera follows mouse slightly
		var offsetX = (FlxG.mouse.screenX - FlxG.width / 2) * 0.05;
		var offsetY = (FlxG.mouse.screenY - FlxG.height / 2) * 0.05;
		FlxG.camera.targetOffset.set(offsetX, offsetY);

		// ESC → back to Title
		if (FlxG.keys.justPressed.ESCAPE && !selectedSomethin) {
			MusicBeatState.switchState(new TitleState());
		}

		// Hover scaling
		for (item in menuItems)
		{
			if (FlxG.mouse.overlaps(item))
			{
				if (item.scale.x < 1.2) {
					FlxTween.tween(item.scale, {x: 1.2, y: 1.2}, 0.2, {ease: FlxEase.quadOut});
				}

				if (FlxG.mouse.justPressed && !selectedSomethin) {
					selectOption(item);
				}
			}
			else if (item.scale.x > 1) {
				FlxTween.tween(item.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.quadIn});
			}
		}

		// Same for rightItem
		if (rightItem != null)
		{
			if (FlxG.mouse.overlaps(rightItem))
			{
				if (rightItem.scale.x < 1.2) {
					FlxTween.tween(rightItem.scale, {x: 1.2, y: 1.2}, 0.2, {ease: FlxEase.quadOut});
				}
				if (FlxG.mouse.justPressed && !selectedSomethin) {
					selectOption(rightItem);
				}
			}
			else if (rightItem.scale.x > 1) {
				FlxTween.tween(rightItem.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.quadIn});
			}
		}

		super.update(elapsed);
	}

	function selectOption(item:FlxSprite)
	{
		selectedSomethin = true;
		item.acceleration.y = 800; // fall with gravity
		item.velocity.y = -200;

		new FlxTimer().start(0.8, function(_) {
			if (item == rightItem) {
				MusicBeatState.switchState(new OptionsState());
			} else {
				switch (optionShit[menuItems.members.indexOf(item)]) {
					case "story_mode":
						MusicBeatState.switchState(new StoryMenuState());
					case "freeplay":
						MusicBeatState.switchState(new FreeplayState());
					case "credits":
						MusicBeatState.switchState(new CreditsState());
				}
			}
		});
	}

	function changeItem(change:Int = 0)
	{
		if (change != 0) curColumn = CENTER;
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		for (item in menuItems)
		{
			item.animation.play('idle');
			item.centerOffsets();
		}

		var selectedItem:FlxSprite;
		switch (curColumn)
		{
			case CENTER:
				selectedItem = menuItems.members[curSelected];
			case LEFT:
				selectedItem = leftItem;
			case RIGHT:
				selectedItem = rightItem;
		}
		selectedItem.animation.play('selected');
		selectedItem.centerOffsets();
		camFollow.y = selectedItem.getGraphicMidpoint().y;
	}
}

package TEMPLATE_PACKAGE.mixin;

import joptsimple.ArgumentAcceptingOptionSpec;
import joptsimple.OptionSet;
import joptsimple.OptionSpec;
import net.minecraft.SharedConstants;
import net.minecraft.client.main.Main;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(Main.class)
public class MixinMain {
	@Inject(method = "getOption", at = @At("HEAD"), cancellable = true)
	private static <T> void debrand$getOption(OptionSet optionSet, OptionSpec<T> optionSpec, CallbackInfoReturnable<T> cir) {
		if (optionSpec instanceof ArgumentAcceptingOptionSpec<T> arg) {
			if (arg.options().contains("version")) {
				//noinspection unchecked
				cir.setReturnValue((T) SharedConstants.getGameVersion().getName());
			} else if (arg.options().contains("versionType")) {
				//noinspection unchecked
				cir.setReturnValue((T) "release");
			}
		}
	}
}

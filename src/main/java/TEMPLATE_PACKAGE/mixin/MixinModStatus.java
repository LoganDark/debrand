package TEMPLATE_PACKAGE.mixin;

import net.minecraft.util.ModStatus;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

@Mixin(ModStatus.class)
public class MixinModStatus {
	@Redirect(method = "check", at = @At(
		value = "INVOKE",
		target = "Ljava/lang/Class;getSigners()[Ljava/lang/Object;"
	))
	private static Object[] debrand$getSigners(Class<?> instance) {
		return new Object[] {};
	}
}

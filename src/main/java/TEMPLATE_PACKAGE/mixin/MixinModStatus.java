package TEMPLATE_PACKAGE.mixin;

import net.minecraft.util.ModCheck;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

@Mixin(ModCheck.class)
public class MixinModStatus {
	@Redirect(method = "identify", at = @At(
		value = "INVOKE",
		target = "Ljava/lang/Class;getSigners()[Ljava/lang/Object;"
	))
	private static Object[] debrand$getSigners(Class<?> instance) {
		return new Object[] {};
	}
}

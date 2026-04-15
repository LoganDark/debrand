package TEST_PACKAGE;

import TEMPLATE_PACKAGE.TEMPLATE_CLASSNAME;
import net.fabricmc.api.ModInitializer;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public final class TEST_CLASSNAME implements ModInitializer {
	private static final Logger LOGGER = LogManager.getLogger(TEST_CLASSNAME.class);
	public static final String MOD_ID = "TEST_MODID";

	@Override
	public void onInitialize() {
		LOGGER.info("Hello from the testmod for " + TEMPLATE_CLASSNAME.MOD_ID + "!");
	}
}
